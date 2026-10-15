# Local SQLite index of the section 9 chain.
# ResearchFinding → PostHocConclusion → SDKContract → ReferenceVector/Test → SDKRelease.
# A row is not a StateID. This class does not commit. An empty list becomes zero links.
class TraceabilityIndex
  CHAIN = %w[ResearchFinding PostHocConclusion SdkContract ReferenceArtifact SdkRelease].freeze

  class << self
    def traceability_path
      Rails.root.join("..", "research-to-sdk-traceability.json")
    end

    def basis_path
      Rails.root.join("..", "sdk-release-basis.json")
    end

    def load!
      traceability_bytes = File.binread(traceability_path)
      basis_bytes = File.binread(basis_path)
      document = JSON.parse(traceability_bytes)
      basis = JSON.parse(basis_bytes)
      acceptance = copy_acceptance(basis)

      ActiveRecord::Base.transaction do
        clear!
        insert_document!(
          document,
          basis,
          acceptance,
          source_sha256: Digest::SHA256.hexdigest(traceability_bytes)
        )
      end

      TraceabilityRecord.sole
    end

    private
      def clear!
        TraceLink.delete_all
        RequirementCoverage.delete_all
        ReferenceArtifact.delete_all
        SdkContract.delete_all
        PostHocConclusion.delete_all
        ResearchFinding.delete_all
        SdkRelease.delete_all
        TraceabilityRecord.delete_all
      end

      def copy_acceptance(basis)
        acceptance = basis.fetch("foundationAcceptance")
        if acceptance.nil? || acceptance.strip.empty?
          raise ArgumentError, "release basis omitted foundationAcceptance"
        end

        acceptance
      end

      def insert_document!(document, basis, acceptance, source_sha256:)
        insert_findings!(document)
        insert_conclusions!(document)
        insert_artifacts!(document)
        release_id = insert_release!(document, basis, acceptance)
        insert_contracts!(document, release_id)
        insert_coverage!(document)
        TraceabilityRecord.create!(
          kind: document.fetch("kind"),
          status: document.fetch("status"),
          research_basis: document.fetch("researchBasis"),
          new_execution: document.fetch("newExecution"),
          limits: JSON.generate(document.fetch("limits")),
          source_sha256: source_sha256,
          basis_claimed_sha256: basis.fetch("Traceability").fetch("sha256"),
          acceptance: acceptance
        )
      end

      def insert_findings!(document)
        ids = []
        document.fetch("postHocConclusions").each { |conclusion| ids.concat(conclusion.fetch("evidenceIds")) }
        document.fetch("chains").each { |chain| ids.concat(chain.fetch("researchFindings")) }
        ids.uniq.each { |external_id| ResearchFinding.create!(external_id: external_id) }
      end

      def insert_conclusions!(document)
        document.fetch("postHocConclusions").each do |conclusion|
          PostHocConclusion.create!(external_id: conclusion.fetch("id"), finding: conclusion.fetch("finding"))
          link_forward!(
            conclusion.fetch("evidenceIds"),
            source_type: "ResearchFinding",
            role: TraceLink::SUPPORTS,
            target_type: "PostHocConclusion",
            target_external_id: conclusion.fetch("id")
          )
        end
      end

      def insert_artifacts!(document)
        document.fetch("canonicalVectors").each do |vector|
          ReferenceArtifact.create!(
            external_id: vector.fetch("id"),
            chain_step: "vector",
            document_kind: vector.fetch("kind"),
            name: vector.fetch("name"),
            source: vector.fetch("source"),
            source_sha256: vector.fetch("sourceSha256"),
            status: vector.fetch("status"),
            json_pointer: vector.fetch("jsonPointer")
          )
        end
        document.fetch("testCases").each do |test_case|
          ReferenceArtifact.create!(
            external_id: test_case.fetch("id"),
            chain_step: "test",
            document_kind: test_case.fetch("kind"),
            test_method: test_case.fetch("method"),
            source: test_case.fetch("source"),
            source_sha256: test_case.fetch("sourceSha256"),
            status: test_case.fetch("status")
          )
        end
      end

      def insert_release!(document, basis, acceptance)
        release_ids = document.fetch("chains").map { |chain| chain.fetch("release") }.uniq
        raise ArgumentError, "section 9 index expects one SDK release id" unless release_ids.one?

        e27_started = basis.fetch("E27Started")
        unless e27_started == true || e27_started == false
          raise ArgumentError, "E27Started must be boolean"
        end

        SdkRelease.create!(
          external_id: release_ids.first,
          acceptance: acceptance,
          e27_started: e27_started,
          recorded_publication: basis.fetch("publication")
        )
        release_ids.first
      end

      def insert_contracts!(document, release_id)
        document.fetch("chains").each_with_index do |chain, position|
          external_id = chain.fetch("contract")
          raise ArgumentError, "contract release drifted from #{release_id}" if chain.fetch("release") != release_id

          SdkContract.create!(
            external_id: external_id,
            position: position,
            classification: chain.fetch("classification"),
            coverage: chain.fetch("coverage"),
            origin: chain.fetch("origin"),
            evaluated_candidate_name: chain["evaluatedCandidateName"],
            implementation_name: chain["implementationName"],
            proposed_public_name: chain["proposedPublicName"],
            public_name_origin: chain["publicNameOrigin"]
          )
          link_forward!(
            chain.fetch("researchFindings"),
            source_type: "ResearchFinding",
            role: TraceLink::EVIDENCE_FOR_CONTRACT,
            target_type: "SdkContract",
            target_external_id: external_id
          )
          link_forward!(
            chain.fetch("postHocConclusions"),
            source_type: "PostHocConclusion",
            role: TraceLink::SUPPORTS,
            target_type: "SdkContract",
            target_external_id: external_id
          )
          # Empty arrays create no rows. A blank target is not stored as proof.
          link_outgoing!(chain.fetch("canonicalVectors"), external_id, TraceLink::REFERENCE_VECTOR, "ReferenceArtifact")
          link_outgoing!(chain.fetch("referenceTests"), external_id, TraceLink::REFERENCE_TEST, "ReferenceArtifact")
          link_outgoing!([ release_id ], external_id, TraceLink::SDK_RELEASE, "SdkRelease")
        end
      end

      def insert_coverage!(document)
        document.fetch("requirementCoverage").each do |coverage|
          RequirementCoverage.create!(
            requirement: coverage.fetch("requirement"),
            status: coverage.fetch("status"),
            limit: coverage.fetch("limit"),
            test_ids: JSON.generate(coverage.fetch("testIds"))
          )
        end
      end

      def link_forward!(source_ids, source_type:, role:, target_type:, target_external_id:)
        target_type.constantize.find_by!(external_id: target_external_id)
        source_ids.each_with_index do |source_external_id, position|
          refuse_empty_target!(source_external_id, role)
          source_type.constantize.find_by!(external_id: source_external_id)
          TraceLink.create!(
            source_type: source_type,
            source_external_id: source_external_id,
            role: role,
            target_type: target_type,
            target_external_id: target_external_id,
            position: position
          )
        end
      end

      def link_outgoing!(target_ids, source_external_id, role, target_type)
        target_ids.each_with_index do |target_external_id, position|
          refuse_empty_target!(target_external_id, role)
          target_type.constantize.find_by!(external_id: target_external_id)
          TraceLink.create!(
            source_type: "SdkContract",
            source_external_id: source_external_id,
            role: role,
            target_type: target_type,
            target_external_id: target_external_id,
            position: position
          )
        end
      end

      def refuse_empty_target!(target_external_id, role)
        return unless target_external_id.nil? || target_external_id.to_s.strip.empty?

        raise ArgumentError, "empty #{role} link is not proof"
      end
  end
end
