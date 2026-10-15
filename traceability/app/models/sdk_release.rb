class SdkRelease < ApplicationRecord
  validates :external_id, :acceptance, :recorded_publication, presence: true
  validates :external_id, uniqueness: true
  validates :e27_started, inclusion: { in: [ true, false ] }
end
