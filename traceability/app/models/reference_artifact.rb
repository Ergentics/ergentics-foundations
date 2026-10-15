class ReferenceArtifact < ApplicationRecord
  CHAIN_STEPS = %w[vector test].freeze

  validates :external_id, :document_kind, :source, :source_sha256, :status, presence: true
  validates :external_id, uniqueness: true
  validates :chain_step, inclusion: { in: CHAIN_STEPS }
end
