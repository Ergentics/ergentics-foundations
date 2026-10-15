class TraceLink < ApplicationRecord
  SUPPORTS = "supports"
  EVIDENCE_FOR_CONTRACT = "evidence_for_contract"
  REFERENCE_VECTOR = "reference_vector"
  REFERENCE_TEST = "reference_test"
  SDK_RELEASE = "sdk_release"
  ROLES = [ SUPPORTS, EVIDENCE_FOR_CONTRACT, REFERENCE_VECTOR, REFERENCE_TEST, SDK_RELEASE ].freeze

  validates :source_type, :source_external_id, :target_type, :target_external_id, presence: true
  validates :role, inclusion: { in: ROLES }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :target_is_a_real_id

  private
    def target_is_a_real_id
      return if target_external_id.nil?

      errors.add(:target_external_id, "empty link is not proof") if target_external_id.strip.empty?
    end
end
