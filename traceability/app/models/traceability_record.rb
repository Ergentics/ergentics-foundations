class TraceabilityRecord < ApplicationRecord
  DOCUMENTED_ORIGIN_STATUS = "PASS_FOR_DOCUMENTED_ORIGIN_AND_COVERAGE_NOT_FULL_IMPLEMENTATION"

  validates :kind, :status, :research_basis, :limits, :source_sha256, :basis_claimed_sha256, :acceptance, presence: true
  validates :new_execution, inclusion: { in: [ true, false ] }

  def limits_list
    JSON.parse(limits)
  end

  def documented_origin_and_coverage_pass?
    status == DOCUMENTED_ORIGIN_STATUS
  end

  def full_implementation?
    status == "FULL_IMPLEMENTATION"
  end

  def bytes_match_basis_claim?
    source_sha256.present? && source_sha256 == basis_claimed_sha256
  end
end
