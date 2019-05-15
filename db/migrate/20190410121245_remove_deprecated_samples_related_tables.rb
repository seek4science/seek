class RemoveDeprecatedSamplesRelatedTables < ActiveRecord::Migration[5.2]
  def up
    drop_table :deprecated_sample_assets
    drop_table :deprecated_sample_auth_lookup
    drop_table :deprecated_samples
    drop_table :deprecated_samples_projects
    drop_table :deprecated_samples_tissue_and_cell_types
    drop_table :deprecated_specimen_auth_lookup
    drop_table :deprecated_specimens
    drop_table :deprecated_specimens_projects
    drop_table :deprecated_treatments
    drop_table :sop_deprecated_specimens
    drop_table :assays_deprecated_samples

  end

  def down
    create_table "deprecated_sample_assets", id: :integer,  force: :cascade do |t|
      t.integer "deprecated_sample_id"
      t.integer "asset_id"
      t.integer "version"
      t.string "asset_type"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "deprecated_sample_auth_lookup", id: false,  force: :cascade do |t|
      t.integer "user_id"
      t.integer "asset_id"
      t.boolean "can_view", default: false
      t.boolean "can_manage", default: false
      t.boolean "can_edit", default: false
      t.boolean "can_download", default: false
      t.boolean "can_delete", default: false
    end

    create_table "deprecated_samples", id: :integer,  force: :cascade do |t|
      t.string "title"
      t.integer "deprecated_specimen_id"
      t.string "lab_internal_number"
      t.datetime "donation_date"
      t.string "explantation"
      t.string "comments"
      t.string "first_letter"
      t.integer "policy_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer "contributor_id"
      t.string "contributor_type"
      t.integer "institution_id"
      t.datetime "sampling_date"
      t.string "organism_part"
      t.string "provider_id"
      t.string "provider_name"
      t.string "age_at_sampling"
      t.string "uuid"
      t.string "sample_type"
      t.string "treatment"
      t.integer "age_at_sampling_unit_id"
    end

    create_table "deprecated_samples_projects", id: false,  force: :cascade do |t|
      t.integer "project_id"
      t.integer "deprecated_sample_id"
    end

    create_table "deprecated_samples_tissue_and_cell_types", id: false,  force: :cascade do |t|
      t.integer "deprecated_sample_id"
      t.integer "tissue_and_cell_type_id"
    end

    create_table "deprecated_specimen_auth_lookup", id: false,  force: :cascade do |t|
      t.integer "user_id"
      t.integer "asset_id"
      t.boolean "can_view", default: false
      t.boolean "can_manage", default: false
      t.boolean "can_edit", default: false
      t.boolean "can_download", default: false
      t.boolean "can_delete", default: false
      t.index ["user_id", "asset_id", "can_view"], name: "index_spec_user_id_asset_id_can_view"
      t.index ["user_id", "can_view"], name: "index_specimen_auth_lookup_on_user_id_and_can_view"
    end

    create_table "deprecated_specimens", id: :integer,  force: :cascade do |t|
      t.string "title"
      t.integer "age"
      t.string "treatment"
      t.string "lab_internal_number"
      t.integer "person_id"
      t.integer "institution_id"
      t.string "comments"
      t.string "first_letter"
      t.integer "policy_id"
      t.text "other_creators", limit: 16777215
      t.integer "contributor_id"
      t.string "contributor_type"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer "culture_growth_type_id"
      t.integer "strain_id"
      t.string "medium"
      t.string "culture_format"
      t.float "temperature"
      t.float "ph"
      t.string "confluency"
      t.string "passage"
      t.string "viability"
      t.string "purity"
      t.integer "sex"
      t.datetime "born"
      t.string "ploidy"
      t.string "provider_id"
      t.string "provider_name"
      t.boolean "is_dummy", default: false
      t.string "uuid"
      t.string "age_unit"
    end

    create_table "deprecated_specimens_projects", id: false,  force: :cascade do |t|
      t.integer "project_id"
      t.integer "deprecated_specimen_id"
    end

    create_table "deprecated_treatments", id: :integer,  force: :cascade do |t|
      t.integer "unit_id"
      t.string "treatment_protocol"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer "deprecated_sample_id"
      t.integer "measured_item_id"
      t.float "start_value"
      t.float "end_value"
      t.float "standard_deviation"
      t.text "comments", limit: 16777215
      t.integer "compound_id"
      t.integer "deprecated_specimen_id"
      t.string "medium_title"
      t.float "time_after_treatment"
      t.integer "time_after_treatment_unit_id"
      t.float "incubation_time"
      t.integer "incubation_time_unit_id"
    end

    create_table "sop_deprecated_specimens", id: :integer,  force: :cascade do |t|
      t.integer "deprecated_specimen_id"
      t.integer "sop_id"
      t.integer "sop_version"
    end

    create_table "assays_deprecated_samples", id: false,  force: :cascade do |t|
      t.integer "assay_id"
      t.integer "deprecated_sample_id"
    end
  end
end
