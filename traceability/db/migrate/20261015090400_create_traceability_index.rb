class CreateTraceabilityIndex < ActiveRecord::Migration[8.1]
  def change
    create_table :research_findings do |t|
      t.string :external_id, null: false
      t.timestamps
    end
    add_index :research_findings, :external_id, unique: true

    create_table :post_hoc_conclusions do |t|
      t.string :external_id, null: false
      t.text :finding, null: false
      t.timestamps
    end
    add_index :post_hoc_conclusions, :external_id, unique: true

    create_table :sdk_contracts do |t|
      t.string :external_id, null: false
      t.integer :position, null: false
      t.string :classification, null: false
      t.string :coverage, null: false
      t.string :origin, null: false
      t.string :evaluated_candidate_name
      t.string :implementation_name
      t.string :proposed_public_name
      t.string :public_name_origin
      t.timestamps
    end
    add_index :sdk_contracts, :external_id, unique: true

    create_table :reference_artifacts do |t|
      t.string :external_id, null: false
      t.string :chain_step, null: false
      t.string :document_kind, null: false
      t.string :name
      t.string :test_method
      t.string :source, null: false
      t.string :source_sha256, null: false
      t.string :status, null: false
      t.string :json_pointer
      t.timestamps
    end
    add_index :reference_artifacts, :external_id, unique: true

    create_table :sdk_releases do |t|
      t.string :external_id, null: false
      t.string :acceptance, null: false
      t.boolean :e27_started, null: false
      t.string :recorded_publication, null: false
      t.timestamps
    end
    add_index :sdk_releases, :external_id, unique: true

    create_table :trace_links do |t|
      t.string :source_type, null: false
      t.string :source_external_id, null: false
      t.string :role, null: false
      t.string :target_type, null: false
      t.string :target_external_id, null: false
      t.integer :position, null: false
      t.timestamps
    end
    add_index :trace_links,
      [ :source_type, :source_external_id, :role, :target_external_id ],
      unique: true,
      name: "index_trace_links_on_edge"
    add_index :trace_links, [ :target_type, :target_external_id ], name: "index_trace_links_on_target"

    create_table :requirement_coverages do |t|
      t.string :requirement, null: false
      t.string :status, null: false
      t.text :limit, null: false
      t.text :test_ids, null: false
      t.timestamps
    end
    add_index :requirement_coverages, :requirement, unique: true

    create_table :traceability_records do |t|
      t.string :kind, null: false
      t.string :status, null: false
      t.string :research_basis, null: false
      t.boolean :new_execution, null: false
      t.text :limits, null: false
      t.string :source_sha256, null: false
      t.string :basis_claimed_sha256, null: false
      t.string :acceptance, null: false
      t.timestamps
    end
  end
end
