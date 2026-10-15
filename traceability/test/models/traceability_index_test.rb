require "test_helper"
require "digest"

class TraceabilityIndexTest < ActiveSupport::TestCase
  setup do
    TraceabilityIndex.load!
    @document = JSON.parse(File.read(TraceabilityIndex.traceability_path))
    @basis = JSON.parse(File.read(TraceabilityIndex.basis_path))
  end

  test "index matches the traceability document and the release basis" do
    assert_equal TraceabilityIndex::CHAIN, %w[ResearchFinding PostHocConclusion SdkContract ReferenceArtifact SdkRelease]
    assert_equal @document.fetch("chains").size, SdkContract.count
    assert_equal @document.fetch("chains").map { |chain| chain.fetch("contract") },
      SdkContract.order(:position).pluck(:external_id)

    @document.fetch("chains").each do |chain|
      contract = SdkContract.find_by!(external_id: chain.fetch("contract"))
      assert_equal chain.fetch("origin"), contract.origin
      assert_equal chain.fetch("classification"), contract.classification
      assert_equal chain.fetch("coverage"), contract.coverage
      assert_equal chain.fetch("researchFindings"), contract.research_finding_ids
      assert_equal chain.fetch("postHocConclusions"), contract.post_hoc_conclusion_ids
      assert_equal chain.fetch("canonicalVectors"), contract.reference_vector_ids
      assert_equal chain.fetch("referenceTests"), contract.reference_test_ids
      assert_equal [ chain.fetch("release") ], contract.release_ids
      assert_optional_field chain, "evaluatedCandidateName", contract.evaluated_candidate_name
      assert_optional_field chain, "implementationName", contract.implementation_name
      assert_optional_field chain, "proposedPublicName", contract.proposed_public_name
      assert_optional_field chain, "publicNameOrigin", contract.public_name_origin
      assert contract.research_finding_ids.any?, "#{contract.external_id} omitted evidence ids"
    end

    @document.fetch("postHocConclusions").each do |conclusion|
      row = PostHocConclusion.find_by!(external_id: conclusion.fetch("id"))
      assert_equal conclusion.fetch("finding"), row.finding
      assert_equal conclusion.fetch("evidenceIds"), row.evidence_ids
    end

    @document.fetch("canonicalVectors").each do |vector|
      row = ReferenceArtifact.find_by!(external_id: vector.fetch("id"))
      assert_equal "vector", row.chain_step
      assert_equal vector.fetch("name"), row.name
      assert_equal vector.fetch("sourceSha256"), row.source_sha256
      assert_equal vector.fetch("jsonPointer"), row.json_pointer
    end

    @document.fetch("testCases").each do |test_case|
      row = ReferenceArtifact.find_by!(external_id: test_case.fetch("id"))
      assert_equal "test", row.chain_step
      assert_equal test_case.fetch("method"), row.test_method
      assert_equal test_case.fetch("sourceSha256"), row.source_sha256
    end

    @document.fetch("requirementCoverage").each do |coverage|
      row = RequirementCoverage.find_by!(requirement: coverage.fetch("requirement"))
      assert_equal coverage.fetch("status"), row.status
      assert_equal coverage.fetch("limit"), row.limit
      assert_equal coverage.fetch("testIds"), row.parsed_test_ids
    end

    record = TraceabilityRecord.sole
    digest = Digest::SHA256.file(TraceabilityIndex.traceability_path).hexdigest
    assert_equal digest, record.source_sha256
    assert_equal @basis.dig("Traceability", "sha256"), record.basis_claimed_sha256
    assert_equal digest, record.basis_claimed_sha256
    assert record.bytes_match_basis_claim?
    assert_equal @document.fetch("limits"), record.limits_list
    assert_equal @document.fetch("researchBasis"), record.research_basis
    assert_equal false, record.new_execution
  end

  test "SDK-Generation keeps zero vector links and that absence is not proof" do
    contract = SdkContract.find_by!(external_id: "SDK-Generation")
    assert_equal [], contract.reference_vector_ids
    assert_equal %w[TEST-02 TEST-06 TEST-12], contract.reference_test_ids
    assert_not contract.reference_vector_linked?
    assert contract.reference_test_linked?
    assert_equal "EXISTING_BOUNDED_REFERENCE", contract.coverage
    assert_equal 0, contract.outgoing(TraceLink::REFERENCE_VECTOR).count
    assert_not TraceLink.exists?(target_external_id: "")

    support = TraceLink.find_by!(
      source_type: "ResearchFinding",
      source_external_id: "EV-E03-REPORT",
      role: TraceLink::SUPPORTS,
      target_external_id: "PH-IDENTITY"
    )
    assert_equal "PostHocConclusion", support.target_type
    conclusion_link = TraceLink.find_by!(
      source_type: "PostHocConclusion",
      source_external_id: "PH-IDENTITY",
      role: TraceLink::SUPPORTS,
      target_external_id: "SDK-Generation"
    )
    assert_equal "SdkContract", conclusion_link.target_type
    assert_equal [ "SDK-0.1.x-PROPOSED" ], contract.release_ids
    assert_equal "SdkRelease", contract.outgoing(TraceLink::SDK_RELEASE).sole.target_type
  end

  test "contract evidence ids stay distinct from conclusion evidence ids" do
    contract = SdkContract.find_by!(external_id: "SDK-Generation")
    assert_equal %w[EV-E03-REPORT EV-E07-REPORT EV-E12-REPORT], contract.research_finding_ids
    assert_equal %w[EV-E03-REPORT EV-E09-REPORT], PostHocConclusion.find_by!(external_id: "PH-IDENTITY").evidence_ids
    assert_not TraceLink.exists?(
      source_external_id: "EV-E07-REPORT",
      role: TraceLink::SUPPORTS,
      target_external_id: "PH-IDENTITY"
    )
  end

  test "deferred and internal contracts keep their documented coverage" do
    object_id = SdkContract.find_by!(external_id: "SDK-ObjectID")
    assert_equal "DEFER", object_id.classification
    assert_equal "DEFERRED_NO_DIRECT_VECTOR", object_id.coverage
    assert_equal "ENGINEERING_DERIVED", object_id.origin
    assert_empty object_id.reference_vector_ids
    assert_empty object_id.reference_test_ids
    assert_not object_id.reference_vector_linked?
    assert_not object_id.reference_test_linked?
    assert object_id.research_finding_ids.any?
    assert_equal [ "SDK-0.1.x-PROPOSED" ], object_id.release_ids

    evidence_root = SdkContract.find_by!(external_id: "SDK-EvidenceRoot")
    assert_equal "ACCEPT_WITH_LIMITATIONS", evidence_root.classification
    assert_empty evidence_root.reference_test_ids
    assert_not evidence_root.reference_test_linked?

    representation = SdkContract.find_by!(external_id: "SDK-Representation")
    assert_equal "INTERNAL_ONLY", representation.classification
    assert representation.reference_vector_linked?

    validation = SdkContract.find_by!(external_id: "SDK-ValidationResult")
    assert_equal "ValidationResult", validation.evaluated_candidate_name
    assert_equal "VerifiedTransition (unchanged)", validation.implementation_name
    assert_equal "AdmissionResult", validation.proposed_public_name
    assert_nil SdkContract.find_by!(external_id: "SDK-Generation").proposed_public_name
    assert_not SdkContract.column_names.include?("cbor")
  end

  test "a blank target cannot be saved as a link" do
    link = TraceLink.new(
      source_type: "SdkContract",
      source_external_id: "SDK-Generation",
      role: TraceLink::REFERENCE_VECTOR,
      target_type: "ReferenceArtifact",
      target_external_id: "",
      position: 0
    )
    assert_not link.valid?
    assert_includes link.errors[:target_external_id], "empty link is not proof"
  end

  test "traceability can pass for documented origin while implementation stays partial" do
    record = TraceabilityRecord.sole
    assert_equal TraceabilityRecord::DOCUMENTED_ORIGIN_STATUS, record.status
    assert_equal @document.fetch("status"), record.status
    assert record.documented_origin_and_coverage_pass?
    assert_not record.full_implementation?

    partial = [
      "wrong parent",
      "sibling lineage",
      "structurally valid evidence without current authority",
      "invalid/expired/revoked authority"
    ]
    partial.each do |requirement|
      row = RequirementCoverage.find_by!(requirement: requirement)
      assert_equal "PARTIAL", row.status, requirement
    end
    parent = RequirementCoverage.find_by!(requirement: "wrong parent")
    assert_equal [ "TEST-10" ], parent.parsed_test_ids
    assert_includes parent.limit, "recursive parents not implemented"
  end

  test "acceptance is stored from the release basis and is not a row count" do
    release = SdkRelease.find_by!(external_id: "SDK-0.1.x-PROPOSED")
    assert_equal "YES_WITH_LIMITATIONS", @basis.fetch("foundationAcceptance")
    assert_equal @basis.fetch("foundationAcceptance"), release.read_attribute(:acceptance)
    assert_equal @basis.fetch("foundationAcceptance"), TraceabilityRecord.sole.read_attribute(:acceptance)
    assert_equal false, release.e27_started
    assert_equal @basis.fetch("publication"), release.recorded_publication
    assert_equal false, @basis.fetch("E27Started")

    SdkContract.delete_all
    TraceLink.delete_all
    assert_equal 0, SdkContract.count
    assert_equal "YES_WITH_LIMITATIONS", release.reload.read_attribute(:acceptance)
  end

  test "a row is not a state id and deleting rows does not change the json" do
    traceability_bytes = File.binread(TraceabilityIndex.traceability_path)
    basis_bytes = File.binread(TraceabilityIndex.basis_path)
    finding = ResearchFinding.find_by!(external_id: "EV-E26-REPORT")

    assert_kind_of Integer, finding.id
    assert_not_equal finding.external_id, finding.id.to_s
    assert_not ResearchFinding.column_names.include?("state_id")
    assert_raises(NoMethodError) { finding.commit }
    tables = ActiveRecord::Base.connection.tables
    assert_not_includes tables, "states"
    assert_not_includes tables, "object_ids"

    ResearchFinding.delete_all
    PostHocConclusion.delete_all
    SdkContract.delete_all
    ReferenceArtifact.delete_all
    SdkRelease.delete_all
    TraceLink.delete_all
    RequirementCoverage.delete_all
    TraceabilityRecord.delete_all

    assert_equal traceability_bytes, File.binread(TraceabilityIndex.traceability_path)
    assert_equal basis_bytes, File.binread(TraceabilityIndex.basis_path)
  end

  test "loading again does not duplicate the chain" do
    counts = [ ResearchFinding.count, SdkContract.count, TraceLink.count, TraceabilityRecord.count ]
    TraceabilityIndex.load!
    assert_equal counts, [ ResearchFinding.count, SdkContract.count, TraceLink.count, TraceabilityRecord.count ]
    assert_equal 1, TraceabilityRecord.count
    assert_equal 1, SdkRelease.count
  end

  private
    def assert_optional_field(chain, key, actual)
      if chain.key?(key)
        assert_equal chain[key], actual
      else
        assert_nil actual
      end
    end
end
