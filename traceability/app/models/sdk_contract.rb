class SdkContract < ApplicationRecord
  validates :external_id, :classification, :coverage, :origin, presence: true
  validates :external_id, uniqueness: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def outgoing(role)
    TraceLink.where(source_type: self.class.name, source_external_id: external_id, role: role)
      .order(:position, :id)
  end

  def incoming(role, source_type:)
    TraceLink.where(
      target_type: self.class.name,
      target_external_id: external_id,
      role: role,
      source_type: source_type
    ).order(:position, :id)
  end

  def research_finding_ids
    incoming(TraceLink::EVIDENCE_FOR_CONTRACT, source_type: "ResearchFinding").pluck(:source_external_id)
  end

  def post_hoc_conclusion_ids
    incoming(TraceLink::SUPPORTS, source_type: "PostHocConclusion").pluck(:source_external_id)
  end

  def reference_vector_ids
    outgoing(TraceLink::REFERENCE_VECTOR).pluck(:target_external_id)
  end

  def reference_test_ids
    outgoing(TraceLink::REFERENCE_TEST).pluck(:target_external_id)
  end

  def release_ids
    outgoing(TraceLink::SDK_RELEASE).pluck(:target_external_id)
  end

  def reference_vector_linked?
    reference_vector_ids.any?
  end

  def reference_test_linked?
    reference_test_ids.any?
  end
end
