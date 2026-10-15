class PostHocConclusion < ApplicationRecord
  validates :external_id, :finding, presence: true
  validates :external_id, uniqueness: true

  def evidence_ids
    TraceLink.where(
      target_type: self.class.name,
      target_external_id: external_id,
      role: TraceLink::SUPPORTS,
      source_type: "ResearchFinding"
    ).order(:position, :id).pluck(:source_external_id)
  end
end
