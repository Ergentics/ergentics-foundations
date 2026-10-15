# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_15_090400) do
  create_table "post_hoc_conclusions", force: :cascade do |t|
    t.string "external_id", null: false
    t.text "finding", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_post_hoc_conclusions_on_external_id", unique: true
  end

  create_table "reference_artifacts", force: :cascade do |t|
    t.string "external_id", null: false
    t.string "chain_step", null: false
    t.string "document_kind", null: false
    t.string "name"
    t.string "test_method"
    t.string "source", null: false
    t.string "source_sha256", null: false
    t.string "status", null: false
    t.string "json_pointer"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_reference_artifacts_on_external_id", unique: true
  end

  create_table "requirement_coverages", force: :cascade do |t|
    t.string "requirement", null: false
    t.string "status", null: false
    t.text "limit", null: false
    t.text "test_ids", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["requirement"], name: "index_requirement_coverages_on_requirement", unique: true
  end

  create_table "research_findings", force: :cascade do |t|
    t.string "external_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_research_findings_on_external_id", unique: true
  end

  create_table "sdk_contracts", force: :cascade do |t|
    t.string "external_id", null: false
    t.integer "position", null: false
    t.string "classification", null: false
    t.string "coverage", null: false
    t.string "origin", null: false
    t.string "evaluated_candidate_name"
    t.string "implementation_name"
    t.string "proposed_public_name"
    t.string "public_name_origin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_sdk_contracts_on_external_id", unique: true
  end

  create_table "sdk_releases", force: :cascade do |t|
    t.string "external_id", null: false
    t.string "acceptance", null: false
    t.boolean "e27_started", null: false
    t.string "recorded_publication", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_sdk_releases_on_external_id", unique: true
  end

  create_table "trace_links", force: :cascade do |t|
    t.string "source_type", null: false
    t.string "source_external_id", null: false
    t.string "role", null: false
    t.string "target_type", null: false
    t.string "target_external_id", null: false
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["source_type", "source_external_id", "role", "target_external_id"], name: "index_trace_links_on_edge", unique: true
    t.index ["target_type", "target_external_id"], name: "index_trace_links_on_target"
  end

  create_table "traceability_records", force: :cascade do |t|
    t.string "kind", null: false
    t.string "status", null: false
    t.string "research_basis", null: false
    t.boolean "new_execution", null: false
    t.text "limits", null: false
    t.string "source_sha256", null: false
    t.string "basis_claimed_sha256", null: false
    t.string "acceptance", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
