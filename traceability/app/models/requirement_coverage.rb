class RequirementCoverage < ApplicationRecord
  validates :requirement, :status, :limit, :test_ids, presence: true
  validates :requirement, uniqueness: true

  def parsed_test_ids
    JSON.parse(test_ids)
  end
end
