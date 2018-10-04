# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180924152253) do

  create_table "activity_logs", force: :cascade do |t|
    t.string   "action",                 limit: 255
    t.string   "format",                 limit: 255
    t.string   "activity_loggable_type", limit: 255
    t.integer  "activity_loggable_id",   limit: 4
    t.string   "culprit_type",           limit: 255
    t.integer  "culprit_id",             limit: 4
    t.string   "referenced_type",        limit: 255
    t.integer  "referenced_id",          limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "http_referer",           limit: 255
    t.text     "user_agent",             limit: 65535
    t.text     "data",                   limit: 16777215
    t.string   "controller_name",        limit: 255
  end

  add_index "activity_logs", ["action"], name: "act_logs_action_index", using: :btree
  add_index "activity_logs", ["activity_loggable_type", "activity_loggable_id"], name: "act_logs_act_loggable_index", using: :btree
  add_index "activity_logs", ["culprit_type", "culprit_id"], name: "act_logs_culprit_index", using: :btree
  add_index "activity_logs", ["format"], name: "act_logs_format_index", using: :btree
  add_index "activity_logs", ["referenced_type", "referenced_id"], name: "act_logs_referenced_index", using: :btree

  create_table "admin_defined_role_programmes", force: :cascade do |t|
    t.integer "programme_id", limit: 4
    t.integer "person_id",    limit: 4
    t.integer "role_mask",    limit: 4
  end

  create_table "admin_defined_role_projects", force: :cascade do |t|
    t.integer "project_id", limit: 4
    t.integer "role_mask",  limit: 4
    t.integer "person_id",  limit: 4
  end

  create_table "annotation_attributes", force: :cascade do |t|
    t.string   "name",       limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "identifier", limit: 255, null: false
  end

  add_index "annotation_attributes", ["name"], name: "index_annotation_attributes_on_name", using: :btree

  create_table "annotation_value_seeds", force: :cascade do |t|
    t.integer  "attribute_id", limit: 4,                     null: false
    t.string   "old_value",    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "value_type",   limit: 50,  default: "FIXME", null: false
    t.integer  "value_id",     limit: 4,   default: 0,       null: false
  end

  add_index "annotation_value_seeds", ["attribute_id"], name: "index_annotation_value_seeds_on_attribute_id", using: :btree

  create_table "annotation_versions", force: :cascade do |t|
    t.integer  "annotation_id",      limit: 4,                     null: false
    t.integer  "version",            limit: 4,                     null: false
    t.integer  "version_creator_id", limit: 4
    t.string   "source_type",        limit: 255,                   null: false
    t.integer  "source_id",          limit: 4,                     null: false
    t.string   "annotatable_type",   limit: 50,                    null: false
    t.integer  "annotatable_id",     limit: 4,                     null: false
    t.integer  "attribute_id",       limit: 4,                     null: false
    t.string   "old_value",          limit: 255, default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "value_type",         limit: 50,  default: "FIXME", null: false
    t.integer  "value_id",           limit: 4,   default: 0,       null: false
  end

  add_index "annotation_versions", ["annotation_id"], name: "index_annotation_versions_on_annotation_id", using: :btree

  create_table "annotations", force: :cascade do |t|
    t.string   "source_type",        limit: 255,                   null: false
    t.integer  "source_id",          limit: 4,                     null: false
    t.string   "annotatable_type",   limit: 50,                    null: false
    t.integer  "annotatable_id",     limit: 4,                     null: false
    t.integer  "attribute_id",       limit: 4,                     null: false
    t.string   "old_value",          limit: 255, default: ""
    t.integer  "version",            limit: 4
    t.integer  "version_creator_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "value_type",         limit: 50,  default: "FIXME", null: false
    t.integer  "value_id",           limit: 4,   default: 0,       null: false
  end

  add_index "annotations", ["annotatable_type", "annotatable_id"], name: "index_annotations_on_annotatable_type_and_annotatable_id", using: :btree
  add_index "annotations", ["attribute_id"], name: "index_annotations_on_attribute_id", using: :btree
  add_index "annotations", ["source_type", "source_id"], name: "index_annotations_on_source_type_and_source_id", using: :btree
  add_index "annotations", ["value_type", "value_id"], name: "index_annotations_on_value_type_and_value_id", using: :btree

  create_table "assay_assets", force: :cascade do |t|
    t.integer  "assay_id",             limit: 4
    t.integer  "asset_id",             limit: 4
    t.integer  "version",              limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "relationship_type_id", limit: 4
    t.string   "asset_type",           limit: 255
    t.integer  "direction",            limit: 4,   default: 0
  end

  add_index "assay_assets", ["assay_id"], name: "index_assay_assets_on_assay_id", using: :btree
  add_index "assay_assets", ["asset_id", "asset_type"], name: "index_assay_assets_on_asset_id_and_asset_type", using: :btree

  create_table "assay_auth_lookup", id: false, force: :cascade do |t|
    t.integer "user_id",      limit: 4
    t.integer "asset_id",     limit: 4
    t.boolean "can_view",               default: false
    t.boolean "can_manage",             default: false
    t.boolean "can_edit",               default: false
    t.boolean "can_download",           default: false
    t.boolean "can_delete",             default: false
  end

  add_index "assay_auth_lookup", ["user_id", "asset_id", "can_view"], name: "index_assay_auth_lookup_on_user_id_and_asset_id_and_can_view", using: :btree
  add_index "assay_auth_lookup", ["user_id", "can_view"], name: "index_assay_auth_lookup_on_user_id_and_can_view", using: :btree

  create_table "assay_classes", force: :cascade do |t|
    t.string   "title",       limit: 255
    t.text     "description", limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "key",         limit: 10
  end

  create_table "assay_organisms", force: :cascade do |t|
    t.integer  "assay_id",                limit: 4
    t.integer  "organism_id",             limit: 4
    t.integer  "culture_growth_type_id",  limit: 4
    t.integer  "strain_id",               limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "tissue_and_cell_type_id", limit: 4
  end

  add_index "assay_organisms", ["assay_id"], name: "index_assay_organisms_on_assay_id", using: :btree
  add_index "assay_organisms", ["organism_id"], name: "index_assay_organisms_on_organism_id", using: :btree

  create_table "assays", force: :cascade do |t|
    t.string   "title",                        limit: 255
    t.text     "description",                  limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "study_id",                     limit: 4
    t.integer  "contributor_id",               limit: 4
    t.string   "first_letter",                 limit: 1
    t.integer  "assay_class_id",               limit: 4
    t.string   "uuid",                         limit: 255
    t.integer  "policy_id",                    limit: 4
    t.integer  "institution_id",               limit: 4
    t.string   "assay_type_uri",               limit: 255
    t.string   "technology_type_uri",          limit: 255
    t.integer  "suggested_assay_type_id",      limit: 4
    t.integer  "suggested_technology_type_id", limit: 4
    t.text     "other_creators",               limit: 65535
    t.string   "deleted_contributor",          limit: 255
  end

  create_table "assays_deprecated_samples", id: false, force: :cascade do |t|
    t.integer "assay_id",             limit: 4
    t.integer "deprecated_sample_id", limit: 4
  end

  create_table "asset_doi_logs", force: :cascade do |t|
    t.string   "asset_type",    limit: 255
    t.integer  "asset_id",      limit: 4
    t.integer  "asset_version", limit: 4
    t.integer  "action",        limit: 4
    t.text     "comment",       limit: 65535
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "user_id",       limit: 4
    t.string   "doi",           limit: 255
  end

  create_table "assets", force: :cascade do |t|
    t.integer  "project_id",    limit: 4
    t.string   "resource_type", limit: 255
    t.integer  "resource_id",   limit: 4
    t.integer  "policy_id",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_used_at"
  end

  create_table "assets_creators", force: :cascade do |t|
    t.integer  "asset_id",   limit: 4
    t.integer  "creator_id", limit: 4
    t.string   "asset_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "assets_creators", ["asset_id", "asset_type"], name: "index_assets_creators_on_asset_id_and_asset_type", using: :btree

  create_table "auth_lookup_update_queues", force: :cascade do |t|
    t.integer  "item_id",    limit: 4
    t.string   "item_type",  limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "priority",   limit: 4,   default: 0
  end

  create_table "avatars", force: :cascade do |t|
    t.string   "owner_type",        limit: 255
    t.integer  "owner_id",          limit: 4
    t.string   "original_filename", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "avatars", ["owner_type", "owner_id"], name: "index_avatars_on_owner_type_and_owner_id", using: :btree

  create_table "bioportal_concepts", force: :cascade do |t|
    t.string  "ontology_id",         limit: 255
    t.string  "concept_uri",         limit: 255
    t.text    "cached_concept_yaml", limit: 65535
    t.integer "conceptable_id",      limit: 4
    t.string  "conceptable_type",    limit: 255
  end

  create_table "cell_ranges", force: :cascade do |t|
    t.integer  "cell_range_id", limit: 4
    t.integer  "worksheet_id",  limit: 4
    t.integer  "start_row",     limit: 4
    t.integer  "start_column",  limit: 4
    t.integer  "end_row",       limit: 4
    t.integer  "end_column",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "compounds", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "content_blobs", force: :cascade do |t|
    t.string   "md5sum",            limit: 255
    t.text     "url",               limit: 65535
    t.string   "uuid",              limit: 255
    t.string   "original_filename", limit: 255
    t.string   "content_type",      limit: 255
    t.integer  "asset_id",          limit: 4
    t.string   "asset_type",        limit: 255
    t.integer  "asset_version",     limit: 4
    t.boolean  "is_webpage",                      default: false
    t.boolean  "external_link"
    t.string   "sha1sum",           limit: 255
    t.integer  "file_size",         limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "content_blobs", ["asset_id", "asset_type"], name: "index_content_blobs_on_asset_id_and_asset_type", using: :btree

  create_table "culture_growth_types", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cultures", force: :cascade do |t|
    t.integer  "organism_id",        limit: 4
    t.integer  "sop_id",             limit: 4
    t.datetime "date_at_sampling"
    t.datetime "culture_start_date"
    t.integer  "age_at_sampling",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "data_file_auth_lookup", id: false, force: :cascade do |t|
    t.integer "user_id",      limit: 4
    t.integer "asset_id",     limit: 4
    t.boolean "can_view"
    t.boolean "can_manage"
    t.boolean "can_edit"
    t.boolean "can_download"
    t.boolean "can_delete",             default: false
  end

  add_index "data_file_auth_lookup", ["user_id", "asset_id", "can_view"], name: "index_data_file_auth_lookup_user_asset_view", using: :btree
  add_index "data_file_auth_lookup", ["user_id", "can_view"], name: "index_data_file_auth_lookup_on_user_id_and_can_view", using: :btree

  create_table "data_file_versions", force: :cascade do |t|
    t.integer  "data_file_id",        limit: 4
    t.integer  "version",             limit: 4
    t.text     "revision_comments",   limit: 65535
    t.integer  "contributor_id",      limit: 4
    t.string   "title",               limit: 255
    t.text     "description",         limit: 65535
    t.integer  "template_id",         limit: 4
    t.datetime "last_used_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_letter",        limit: 1
    t.text     "other_creators",      limit: 65535
    t.string   "uuid",                limit: 255
    t.integer  "policy_id",           limit: 4
    t.string   "doi",                 limit: 255
    t.string   "license",             limit: 255
    t.boolean  "simulation_data",                   default: false
    t.string   "deleted_contributor", limit: 255
  end

  add_index "data_file_versions", ["contributor_id"], name: "index_data_file_versions_contributor", using: :btree
  add_index "data_file_versions", ["data_file_id"], name: "index_data_file_versions_on_data_file_id", using: :btree

  create_table "data_file_versions_projects", id: false, force: :cascade do |t|
    t.integer "project_id", limit: 4
    t.integer "version_id", limit: 4
  end

  create_table "data_files", force: :cascade do |t|
    t.integer  "contributor_id",      limit: 4
    t.string   "title",               limit: 255
    t.text     "description",         limit: 65535
    t.integer  "template_id",         limit: 4
    t.datetime "last_used_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "version",             limit: 4,     default: 1
    t.string   "first_letter",        limit: 1
    t.text     "other_creators",      limit: 65535
    t.string   "uuid",                limit: 255
    t.integer  "policy_id",           limit: 4
    t.string   "doi",                 limit: 255
    t.string   "license",             limit: 255
    t.boolean  "simulation_data",                   default: false
    t.string   "deleted_contributor", limit: 255
  end

  add_index "data_files", ["contributor_id"], name: "index_data_files_on_contributor", using: :btree

  create_table "data_files_events", id: false, force: :cascade do |t|
    t.integer "data_file_id", limit: 4
    t.integer "event_id",     limit: 4
  end

  create_table "data_files_projects", id: false, force: :cascade do |t|
    t.integer "project_id",   limit: 4
    t.integer "data_file_id", limit: 4
  end

  add_index "data_files_projects", ["data_file_id", "project_id"], name: "index_data_files_projects_on_data_file_id_and_project_id", using: :btree
  add_index "data_files_projects", ["project_id"], name: "index_data_files_projects_on_project_id", using: :btree

  create_table "db_files", force: :cascade do |t|
    t.binary "data", limit: 65535
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   limit: 4,     default: 0
    t.integer  "attempts",   limit: 4,     default: 0
    t.text     "handler",    limit: 65535
    t.text     "last_error", limit: 65535
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.string   "queue",      limit: 255
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "deprecated_sample_assets", force: :cascade do |t|
    t.integer  "deprecated_sample_id", limit: 4
    t.integer  "asset_id",             limit: 4
    t.integer  "version",              limit: 4
    t.string   "asset_type",           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "deprecated_sample_auth_lookup", id: false, force: :cascade do |t|
    t.integer "user_id",      limit: 4
    t.integer "asset_id",     limit: 4
    t.boolean "can_view",               default: false
    t.boolean "can_manage",             default: false
    t.boolean "can_edit",               default: false
    t.boolean "can_download",           default: false
    t.boolean "can_delete",             default: false
  end

  create_table "deprecated_samples", force: :cascade do |t|
    t.string   "title",                   limit: 255
    t.integer  "deprecated_specimen_id",  limit: 4
    t.string   "lab_internal_number",     limit: 255
    t.datetime "donation_date"
    t.string   "explantation",            limit: 255
    t.string   "comments",                limit: 255
    t.string   "first_letter",            limit: 255
    t.integer  "policy_id",               limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "contributor_id",          limit: 4
    t.string   "contributor_type",        limit: 255
    t.integer  "institution_id",          limit: 4
    t.datetime "sampling_date"
    t.string   "organism_part",           limit: 255
    t.string   "provider_id",             limit: 255
    t.string   "provider_name",           limit: 255
    t.string   "age_at_sampling",         limit: 255
    t.string   "uuid",                    limit: 255
    t.integer  "age_at_sampling_unit_id", limit: 4
    t.string   "sample_type",             limit: 255
    t.string   "treatment",               limit: 255
  end

  create_table "deprecated_samples_projects", id: false, force: :cascade do |t|
    t.integer "project_id",           limit: 4
    t.integer "deprecated_sample_id", limit: 4
  end

  create_table "deprecated_samples_tissue_and_cell_types", id: false, force: :cascade do |t|
    t.integer "deprecated_sample_id",    limit: 4
    t.integer "tissue_and_cell_type_id", limit: 4
  end

  create_table "deprecated_specimen_auth_lookup", id: false, force: :cascade do |t|
    t.integer "user_id",      limit: 4
    t.integer "asset_id",     limit: 4
    t.boolean "can_view",               default: false
    t.boolean "can_manage",             default: false
    t.boolean "can_edit",               default: false
    t.boolean "can_download",           default: false
    t.boolean "can_delete",             default: false
  end

  add_index "deprecated_specimen_auth_lookup", ["user_id", "asset_id", "can_view"], name: "index_spec_user_id_asset_id_can_view", using: :btree
  add_index "deprecated_specimen_auth_lookup", ["user_id", "can_view"], name: "index_specimen_auth_lookup_on_user_id_and_can_view", using: :btree

  create_table "deprecated_specimens", force: :cascade do |t|
    t.string   "title",                  limit: 255
    t.integer  "age",                    limit: 4
    t.string   "treatment",              limit: 255
    t.string   "lab_internal_number",    limit: 255
    t.integer  "person_id",              limit: 4
    t.integer  "institution_id",         limit: 4
    t.string   "comments",               limit: 255
    t.string   "first_letter",           limit: 255
    t.integer  "policy_id",              limit: 4
    t.text     "other_creators",         limit: 65535
    t.integer  "contributor_id",         limit: 4
    t.string   "contributor_type",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "culture_growth_type_id", limit: 4
    t.integer  "strain_id",              limit: 4
    t.string   "medium",                 limit: 255
    t.string   "culture_format",         limit: 255
    t.float    "temperature",            limit: 24
    t.float    "ph",                     limit: 24
    t.string   "confluency",             limit: 255
    t.string   "passage",                limit: 255
    t.string   "viability",              limit: 255
    t.string   "purity",                 limit: 255
    t.integer  "sex",                    limit: 4
    t.datetime "born"
    t.string   "ploidy",                 limit: 255
    t.string   "provider_id",            limit: 255
    t.string   "provider_name",          limit: 255
    t.boolean  "is_dummy",                             default: false
    t.string   "uuid",                   limit: 255
    t.string   "age_unit",               limit: 255
  end

  create_table "deprecated_specimens_projects", id: false, force: :cascade do |t|
    t.integer "project_id",             limit: 4
    t.integer "deprecated_specimen_id", limit: 4
  end

  create_table "deprecated_treatments", force: :cascade do |t|
    t.integer  "unit_id",                      limit: 4
    t.string   "treatment_protocol",           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "deprecated_sample_id",         limit: 4
    t.integer  "measured_item_id",             limit: 4
    t.float    "start_value",                  limit: 24
    t.float    "end_value",                    limit: 24
    t.float    "standard_deviation",           limit: 24
    t.text     "comments",                     limit: 65535
    t.integer  "compound_id",                  limit: 4
    t.integer  "deprecated_specimen_id",       limit: 4
    t.string   "medium_title",                 limit: 255
    t.float    "time_after_treatment",         limit: 24
    t.integer  "time_after_treatment_unit_id", limit: 4
    t.float    "incubation_time",              limit: 24
    t.integer  "incubation_time_unit_id",      limit: 4
  end

  create_table "disciplines", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "disciplines_people", id: false, force: :cascade do |t|
    t.integer "discipline_id", limit: 4
    t.integer "person_id",     limit: 4
  end

  add_index "disciplines_people", ["person_id"], name: "index_disciplines_people_on_person_id", using: :btree

  create_table "document_auth_lookup", force: :cascade do |t|
    t.integer "user_id",      limit: 4
    t.integer "asset_id",     limit: 4
    t.boolean "can_view",               default: false
    t.boolean "can_manage",             default: false
    t.boolean "can_edit",               default: false
    t.boolean "can_download",           default: false
    t.boolean "can_delete",             default: false
  end

  add_index "document_auth_lookup", ["user_id", "asset_id", "can_view"], name: "index_document_user_id_asset_id_can_view", using: :btree
  add_index "document_auth_lookup", ["user_id", "can_view"], name: "index_document_auth_lookup_on_user_id_and_can_view", using: :btree

  create_table "document_versions", force: :cascade do |t|
    t.integer  "document_id",         limit: 4
    t.integer  "version",             limit: 4
    t.text     "revision_comments",   limit: 65535
    t.text     "title",               limit: 65535
    t.text     "description",         limit: 65535
    t.integer  "contributor_id",      limit: 4
    t.string   "first_letter",        limit: 1
    t.string   "uuid",                limit: 255
    t.integer  "policy_id",           limit: 4
    t.string   "doi",                 limit: 255
    t.string   "license",             limit: 255
    t.datetime "last_used_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "other_creators",      limit: 65535
    t.string   "deleted_contributor", limit: 255
  end

  add_index "document_versions", ["contributor_id"], name: "index_document_versions_on_contributor", using: :btree
  add_index "document_versions", ["document_id"], name: "index_document_versions_on_document_id", using: :btree

  create_table "document_versions_projects", force: :cascade do |t|
    t.integer "version_id", limit: 4
    t.integer "project_id", limit: 4
  end

  add_index "document_versions_projects", ["project_id"], name: "index_document_versions_projects_on_project_id", using: :btree
  add_index "document_versions_projects", ["version_id", "project_id"], name: "index_document_versions_projects_on_version_id_and_project_id", using: :btree

  create_table "documents", force: :cascade do |t|
    t.text     "title",               limit: 65535
    t.text     "description",         limit: 65535
    t.integer  "contributor_id",      limit: 4
    t.integer  "version",             limit: 4
    t.string   "first_letter",        limit: 1
    t.string   "uuid",                limit: 255
    t.integer  "policy_id",           limit: 4
    t.string   "doi",                 limit: 255
    t.string   "license",             limit: 255
    t.datetime "last_used_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "other_creators",      limit: 65535
    t.string   "deleted_contributor", limit: 255
  end

  add_index "documents", ["contributor_id"], name: "index_documents_on_contributor", using: :btree

  create_table "documents_events", id: false, force: :cascade do |t|
    t.integer "document_id", limit: 4, null: false
    t.integer "event_id",    limit: 4, null: false
  end

  add_index "documents_events", ["document_id", "event_id"], name: "index_documents_events_on_document_id_and_event_id", using: :btree
  add_index "documents_events", ["event_id", "document_id"], name: "index_documents_events_on_event_id_and_document_id", using: :btree

  create_table "documents_projects", force: :cascade do |t|
    t.integer "document_id", limit: 4
    t.integer "project_id",  limit: 4
  end

  add_index "documents_projects", ["document_id", "project_id"], name: "index_documents_projects_on_document_id_and_project_id", using: :btree
  add_index "documents_projects", ["project_id"], name: "index_documents_projects_on_project_id", using: :btree

  create_table "event_auth_lookup", id: false, force: :cascade do |t|
    t.integer "user_id",      limit: 4
    t.integer "asset_id",     limit: 4
    t.boolean "can_view",               default: false
    t.boolean "can_manage",             default: false
    t.boolean "can_edit",               default: false
    t.boolean "can_download",           default: false
    t.boolean "can_delete",             default: false
  end

  add_index "event_auth_lookup", ["user_id", "asset_id", "can_view"], name: "index_event_auth_lookup_on_user_id_and_asset_id_and_can_view", using: :btree
  add_index "event_auth_lookup", ["user_id", "can_view"], name: "index_event_auth_lookup_on_user_id_and_can_view", using: :btree

  create_table "events", force: :cascade do |t|
    t.datetime "start_date"
    t.datetime "end_date"
    t.text     "address",             limit: 65535
    t.string   "city",                limit: 255
    t.string   "country",             limit: 255
    t.string   "url",                 limit: 255
    t.text     "description",         limit: 65535
    t.string   "title",               limit: 255
    t.integer  "policy_id",           limit: 4
    t.integer  "contributor_id",      limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_letter",        limit: 1
    t.string   "uuid",                limit: 255
    t.string   "deleted_contributor", limit: 255
  end

  create_table "events_presentations", id: false, force: :cascade do |t|
    t.integer "presentation_id", limit: 4
    t.integer "event_id",        limit: 4
  end

  create_table "events_projects", id: false, force: :cascade do |t|
    t.integer "project_id", limit: 4
    t.integer "event_id",   limit: 4
  end

  add_index "events_projects", ["event_id", "project_id"], name: "index_events_projects_on_event_id_and_project_id", using: :btree
  add_index "events_projects", ["project_id"], name: "index_events_projects_on_project_id", using: :btree

  create_table "events_publications", id: false, force: :cascade do |t|
    t.integer "publication_id", limit: 4
    t.integer "event_id",       limit: 4
  end

  create_table "experimental_condition_links", force: :cascade do |t|
    t.string   "substance_type",            limit: 255
    t.integer  "substance_id",              limit: 4
    t.integer  "experimental_condition_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "experimental_conditions", force: :cascade do |t|
    t.integer  "measured_item_id", limit: 4
    t.float    "start_value",      limit: 24
    t.float    "end_value",        limit: 24
    t.integer  "unit_id",          limit: 4
    t.integer  "sop_id",           limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sop_version",      limit: 4
  end

  add_index "experimental_conditions", ["sop_id"], name: "index_experimental_conditions_on_sop_id", using: :btree

  create_table "favourite_group_memberships", force: :cascade do |t|
    t.integer  "person_id",          limit: 4
    t.integer  "favourite_group_id", limit: 4
    t.integer  "access_type",        limit: 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "favourite_groups", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "favourites", force: :cascade do |t|
    t.integer  "resource_id",   limit: 4
    t.integer  "user_id",       limit: 4
    t.string   "resource_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "genes", force: :cascade do |t|
    t.string   "title",       limit: 255
    t.string   "symbol",      limit: 255
    t.text     "description", limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "genotypes", force: :cascade do |t|
    t.integer  "gene_id",                limit: 4
    t.integer  "modification_id",        limit: 4
    t.integer  "strain_id",              limit: 4
    t.text     "comment",                limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "deprecated_specimen_id", limit: 4
  end

  create_table "group_memberships", force: :cascade do |t|
    t.integer  "person_id",     limit: 4
    t.integer  "work_group_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "time_left_at"
  end

  add_index "group_memberships", ["person_id"], name: "index_group_memberships_on_person_id", using: :btree
  add_index "group_memberships", ["work_group_id", "person_id"], name: "index_group_memberships_on_work_group_id_and_person_id", using: :btree
  add_index "group_memberships", ["work_group_id"], name: "index_group_memberships_on_work_group_id", using: :btree

  create_table "group_memberships_project_positions", force: :cascade do |t|
    t.integer "group_membership_id", limit: 4
    t.integer "project_position_id", limit: 4
  end

  create_table "help_attachments", force: :cascade do |t|
    t.integer  "help_document_id", limit: 4
    t.string   "title",            limit: 255
    t.string   "content_type",     limit: 255
    t.string   "filename",         limit: 255
    t.integer  "size",             limit: 4
    t.integer  "db_file_id",       limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "help_documents", force: :cascade do |t|
    t.string   "identifier", limit: 255
    t.string   "title",      limit: 255
    t.text     "body",       limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "help_images", force: :cascade do |t|
    t.integer  "help_document_id", limit: 4
    t.string   "content_type",     limit: 255
    t.string   "filename",         limit: 255
    t.integer  "size",             limit: 4
    t.integer  "height",           limit: 4
    t.integer  "width",            limit: 4
    t.integer  "parent_id",        limit: 4
    t.string   "thumbnail",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "institutions", force: :cascade do |t|
    t.string   "title",        limit: 255
    t.text     "address",      limit: 65535
    t.string   "city",         limit: 255
    t.string   "web_page",     limit: 255
    t.string   "country",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "avatar_id",    limit: 4
    t.string   "first_letter", limit: 1
    t.string   "uuid",         limit: 255
  end

  create_table "investigation_auth_lookup", id: false, force: :cascade do |t|
    t.integer "user_id",      limit: 4
    t.integer "asset_id",     limit: 4
    t.boolean "can_view",               default: false
    t.boolean "can_manage",             default: false
    t.boolean "can_edit",               default: false
    t.boolean "can_download",           default: false
    t.boolean "can_delete",             default: false
  end

  add_index "investigation_auth_lookup", ["user_id", "asset_id", "can_view"], name: "index_inv_user_id_asset_id_can_view", using: :btree
  add_index "investigation_auth_lookup", ["user_id", "can_view"], name: "index_investigation_auth_lookup_on_user_id_and_can_view", using: :btree

  create_table "investigations", force: :cascade do |t|
    t.string   "title",               limit: 255
    t.text     "description",         limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_letter",        limit: 1
    t.string   "uuid",                limit: 255
    t.integer  "policy_id",           limit: 4
    t.integer  "contributor_id",      limit: 4
    t.text     "other_creators",      limit: 65535
    t.string   "deleted_contributor", limit: 255
  end

  create_table "investigations_projects", id: false, force: :cascade do |t|
    t.integer "project_id",       limit: 4
    t.integer "investigation_id", limit: 4
  end

  add_index "investigations_projects", ["investigation_id", "project_id"], name: "index_investigations_projects_inv_proj_id", using: :btree
  add_index "investigations_projects", ["project_id"], name: "index_investigations_projects_on_project_id", using: :btree

  create_table "mapping_links", force: :cascade do |t|
    t.string   "substance_type", limit: 255
    t.integer  "substance_id",   limit: 4
    t.integer  "mapping_id",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mappings", force: :cascade do |t|
    t.integer  "sabiork_id", limit: 4
    t.string   "chebi_id",   limit: 255
    t.string   "kegg_id",    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "measured_items", force: :cascade do |t|
    t.string   "title",           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "factors_studied",             default: true
  end

  create_table "message_logs", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "message_type",  limit: 4
    t.text     "details",       limit: 65535
    t.integer  "resource_id",   limit: 4
    t.string   "resource_type", limit: 255
    t.integer  "sender_id",     limit: 4
  end

  add_index "message_logs", ["resource_type", "resource_id"], name: "index_message_logs_on_resource_type_and_resource_id", using: :btree
  add_index "message_logs", ["sender_id"], name: "index_message_logs_on_sender_id", using: :btree

  create_table "model_auth_lookup", id: false, force: :cascade do |t|
    t.integer "user_id",      limit: 4
    t.integer "asset_id",     limit: 4
    t.boolean "can_view",               default: false
    t.boolean "can_manage",             default: false
    t.boolean "can_edit",               default: false
    t.boolean "can_download",           default: false
    t.boolean "can_delete",             default: false
  end

  add_index "model_auth_lookup", ["user_id", "asset_id", "can_view"], name: "index_model_auth_lookup_on_user_id_and_asset_id_and_can_view", using: :btree
  add_index "model_auth_lookup", ["user_id", "can_view"], name: "index_model_auth_lookup_on_user_id_and_can_view", using: :btree

  create_table "model_formats", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "model_images", force: :cascade do |t|
    t.integer  "model_id",          limit: 4
    t.string   "original_filename", limit: 255
    t.string   "content_type",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "image_width",       limit: 4
    t.integer  "image_height",      limit: 4
  end

  create_table "model_types", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "model_versions", force: :cascade do |t|
    t.integer  "model_id",                   limit: 4
    t.integer  "version",                    limit: 4
    t.text     "revision_comments",          limit: 65535
    t.integer  "contributor_id",             limit: 4
    t.string   "title",                      limit: 255
    t.text     "description",                limit: 65535
    t.integer  "recommended_environment_id", limit: 4
    t.datetime "last_used_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "organism_id",                limit: 4
    t.integer  "model_type_id",              limit: 4
    t.integer  "model_format_id",            limit: 4
    t.string   "first_letter",               limit: 1
    t.text     "other_creators",             limit: 65535
    t.string   "uuid",                       limit: 255
    t.integer  "policy_id",                  limit: 4
    t.string   "imported_source",            limit: 255
    t.string   "imported_url",               limit: 255
    t.integer  "model_image_id",             limit: 4
    t.string   "doi",                        limit: 255
    t.string   "license",                    limit: 255
    t.string   "deleted_contributor",        limit: 255
  end

  add_index "model_versions", ["contributor_id"], name: "index_model_versions_on_contributor", using: :btree
  add_index "model_versions", ["model_id"], name: "index_model_versions_on_model_id", using: :btree

  create_table "model_versions_projects", id: false, force: :cascade do |t|
    t.integer "project_id", limit: 4
    t.integer "version_id", limit: 4
  end

  create_table "models", force: :cascade do |t|
    t.integer  "contributor_id",             limit: 4
    t.string   "title",                      limit: 255
    t.text     "description",                limit: 65535
    t.integer  "recommended_environment_id", limit: 4
    t.datetime "last_used_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "organism_id",                limit: 4
    t.integer  "model_type_id",              limit: 4
    t.integer  "model_format_id",            limit: 4
    t.integer  "version",                    limit: 4,     default: 1
    t.string   "first_letter",               limit: 1
    t.text     "other_creators",             limit: 65535
    t.string   "uuid",                       limit: 255
    t.integer  "policy_id",                  limit: 4
    t.string   "imported_source",            limit: 255
    t.string   "imported_url",               limit: 255
    t.integer  "model_image_id",             limit: 4
    t.string   "doi",                        limit: 255
    t.string   "license",                    limit: 255
    t.string   "deleted_contributor",        limit: 255
  end

  add_index "models", ["contributor_id"], name: "index_models_on_contributor", using: :btree

  create_table "models_projects", id: false, force: :cascade do |t|
    t.integer "project_id", limit: 4
    t.integer "model_id",   limit: 4
  end

  add_index "models_projects", ["model_id", "project_id"], name: "index_models_projects_on_model_id_and_project_id", using: :btree
  add_index "models_projects", ["project_id"], name: "index_models_projects_on_project_id", using: :btree

  create_table "moderatorships", force: :cascade do |t|
    t.integer "forum_id", limit: 4
    t.integer "user_id",  limit: 4
  end

  add_index "moderatorships", ["forum_id"], name: "index_moderatorships_on_forum_id", using: :btree

  create_table "modifications", force: :cascade do |t|
    t.string   "title",       limit: 255
    t.string   "symbol",      limit: 255
    t.text     "description", limit: 65535
    t.string   "position",    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "monitorships", force: :cascade do |t|
    t.integer "topic_id", limit: 4
    t.integer "user_id",  limit: 4
    t.boolean "active",             default: true
  end

  create_table "notifiee_infos", force: :cascade do |t|
    t.integer  "notifiee_id",           limit: 4
    t.string   "notifiee_type",         limit: 255
    t.string   "unique_key",            limit: 255
    t.boolean  "receive_notifications",             default: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "number_value_versions", force: :cascade do |t|
    t.integer  "number_value_id",    limit: 4, null: false
    t.integer  "version",            limit: 4, null: false
    t.integer  "version_creator_id", limit: 4
    t.integer  "number",             limit: 4, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "number_value_versions", ["number_value_id"], name: "index_number_value_versions_on_number_value_id", using: :btree

  create_table "number_values", force: :cascade do |t|
    t.integer  "version",            limit: 4
    t.integer  "version_creator_id", limit: 4
    t.integer  "number",             limit: 4, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "oauth_sessions", force: :cascade do |t|
    t.integer  "user_id",       limit: 4
    t.string   "provider",      limit: 255
    t.string   "access_token",  limit: 255
    t.string   "refresh_token", limit: 255
    t.datetime "expires_at"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "oauth_sessions", ["user_id"], name: "index_oauth_sessions_on_user_id", using: :btree

  create_table "openbis_endpoints", force: :cascade do |t|
    t.string   "as_endpoint",           limit: 255
    t.string   "space_perm_id",         limit: 255
    t.string   "username",              limit: 255
    t.integer  "project_id",            limit: 4
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.string   "dss_endpoint",          limit: 255
    t.string   "web_endpoint",          limit: 255
    t.integer  "refresh_period_mins",   limit: 4,   default: 120
    t.integer  "policy_id",             limit: 4
    t.string   "encrypted_password",    limit: 255
    t.string   "encrypted_password_iv", limit: 255
  end

  create_table "organisms", force: :cascade do |t|
    t.string   "title",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_letter", limit: 255
    t.string   "uuid",         limit: 255
  end

  create_table "organisms_projects", id: false, force: :cascade do |t|
    t.integer "organism_id", limit: 4
    t.integer "project_id",  limit: 4
  end

  add_index "organisms_projects", ["organism_id", "project_id"], name: "index_organisms_projects_on_organism_id_and_project_id", using: :btree
  add_index "organisms_projects", ["project_id"], name: "index_organisms_projects_on_project_id", using: :btree

  create_table "people", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_name",   limit: 255
    t.string   "last_name",    limit: 255
    t.string   "email",        limit: 255
    t.string   "phone",        limit: 255
    t.string   "skype_name",   limit: 255
    t.string   "web_page",     limit: 255
    t.text     "description",  limit: 65535
    t.integer  "avatar_id",    limit: 4
    t.integer  "status_id",    limit: 4,     default: 0
    t.string   "first_letter", limit: 10
    t.string   "uuid",         limit: 255
    t.integer  "roles_mask",   limit: 4,     default: 0
    t.string   "orcid",        limit: 255
  end

  create_table "permissions", force: :cascade do |t|
    t.string   "contributor_type", limit: 255
    t.integer  "contributor_id",   limit: 4
    t.integer  "policy_id",        limit: 4
    t.integer  "access_type",      limit: 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "permissions", ["policy_id"], name: "index_permissions_on_policy_id", using: :btree

  create_table "phenotypes", force: :cascade do |t|
    t.text     "description",            limit: 65535
    t.text     "comment",                limit: 65535
    t.integer  "strain_id",              limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "deprecated_specimen_id", limit: 4
  end

  create_table "policies", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.integer  "sharing_scope", limit: 1
    t.integer  "access_type",   limit: 1
    t.boolean  "use_whitelist"
    t.boolean  "use_blacklist"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "presentation_auth_lookup", id: false, force: :cascade do |t|
    t.integer "user_id",      limit: 4
    t.integer "asset_id",     limit: 4
    t.boolean "can_view",               default: false
    t.boolean "can_manage",             default: false
    t.boolean "can_edit",               default: false
    t.boolean "can_download",           default: false
    t.boolean "can_delete",             default: false
  end

  add_index "presentation_auth_lookup", ["user_id", "asset_id", "can_view"], name: "index_presentation_user_id_asset_id_can_view", using: :btree
  add_index "presentation_auth_lookup", ["user_id", "can_view"], name: "index_presentation_auth_lookup_on_user_id_and_can_view", using: :btree

  create_table "presentation_versions", force: :cascade do |t|
    t.integer  "presentation_id",     limit: 4
    t.integer  "version",             limit: 4
    t.text     "revision_comments",   limit: 65535
    t.integer  "contributor_id",      limit: 4
    t.string   "title",               limit: 255
    t.text     "description",         limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_used_at"
    t.string   "first_letter",        limit: 1
    t.text     "other_creators",      limit: 65535
    t.string   "uuid",                limit: 255
    t.integer  "policy_id",           limit: 4
    t.string   "license",             limit: 255
    t.string   "deleted_contributor", limit: 255
  end

  create_table "presentation_versions_projects", id: false, force: :cascade do |t|
    t.integer "project_id", limit: 4
    t.integer "version_id", limit: 4
  end

  create_table "presentations", force: :cascade do |t|
    t.integer  "contributor_id",      limit: 4
    t.string   "title",               limit: 255
    t.text     "description",         limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_used_at"
    t.integer  "version",             limit: 4,     default: 1
    t.string   "first_letter",        limit: 1
    t.text     "other_creators",      limit: 65535
    t.string   "uuid",                limit: 255
    t.integer  "policy_id",           limit: 4
    t.string   "license",             limit: 255
    t.string   "deleted_contributor", limit: 255
  end

  create_table "presentations_projects", id: false, force: :cascade do |t|
    t.integer "project_id",      limit: 4
    t.integer "presentation_id", limit: 4
  end

  add_index "presentations_projects", ["presentation_id", "project_id"], name: "index_presentations_projects_pres_proj_id", using: :btree
  add_index "presentations_projects", ["project_id"], name: "index_presentations_projects_on_project_id", using: :btree

  create_table "programmes", force: :cascade do |t|
    t.string   "title",                       limit: 255
    t.text     "description",                 limit: 65535
    t.integer  "avatar_id",                   limit: 4
    t.string   "web_page",                    limit: 255
    t.string   "first_letter",                limit: 1
    t.string   "uuid",                        limit: 255
    t.datetime "created_at",                                                null: false
    t.datetime "updated_at",                                                null: false
    t.text     "funding_details",             limit: 65535
    t.boolean  "is_activated",                              default: false
    t.text     "activation_rejection_reason", limit: 65535
  end

  create_table "project_descendants", id: false, force: :cascade do |t|
    t.integer "ancestor_id",   limit: 4
    t.integer "descendant_id", limit: 4
  end

  create_table "project_folder_assets", force: :cascade do |t|
    t.integer  "asset_id",          limit: 4
    t.string   "asset_type",        limit: 255
    t.integer  "project_folder_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "project_folders", force: :cascade do |t|
    t.integer  "project_id",  limit: 4
    t.string   "title",       limit: 255
    t.text     "description", limit: 65535
    t.integer  "parent_id",   limit: 4
    t.boolean  "editable",                  default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "incoming",                  default: false
    t.boolean  "deletable",                 default: true
  end

  create_table "project_positions", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "project_subscriptions", force: :cascade do |t|
    t.integer "person_id",          limit: 4
    t.integer "project_id",         limit: 4
    t.string  "unsubscribed_types", limit: 255
    t.string  "frequency",          limit: 255
  end

  add_index "project_subscriptions", ["person_id", "project_id"], name: "index_project_subscriptions_on_person_id_and_project_id", using: :btree

  create_table "projects", force: :cascade do |t|
    t.string   "title",              limit: 255
    t.string   "web_page",           limit: 255
    t.string   "wiki_page",          limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description",        limit: 65535
    t.integer  "avatar_id",          limit: 4
    t.integer  "default_policy_id",  limit: 4
    t.string   "first_letter",       limit: 1
    t.string   "site_credentials",   limit: 255
    t.string   "site_root_uri",      limit: 255
    t.datetime "last_jerm_run"
    t.string   "uuid",               limit: 255
    t.integer  "programme_id",       limit: 4
    t.integer  "ancestor_id",        limit: 4
    t.integer  "parent_id",          limit: 4
    t.string   "default_license",    limit: 255,   default: "CC-BY-4.0"
    t.boolean  "use_default_policy",               default: false
  end

  create_table "projects_publications", id: false, force: :cascade do |t|
    t.integer "project_id",     limit: 4
    t.integer "publication_id", limit: 4
  end

  add_index "projects_publications", ["project_id"], name: "index_projects_publications_on_project_id", using: :btree
  add_index "projects_publications", ["publication_id", "project_id"], name: "index_projects_publications_on_publication_id_and_project_id", using: :btree

  create_table "projects_sample_types", id: false, force: :cascade do |t|
    t.integer "project_id",     limit: 4
    t.integer "sample_type_id", limit: 4
  end

  add_index "projects_sample_types", ["project_id"], name: "index_projects_sample_types_on_project_id", using: :btree
  add_index "projects_sample_types", ["sample_type_id", "project_id"], name: "index_projects_sample_types_on_sample_type_id_and_project_id", using: :btree

  create_table "projects_samples", id: false, force: :cascade do |t|
    t.integer "project_id", limit: 4
    t.integer "sample_id",  limit: 4
  end

  create_table "projects_sop_versions", id: false, force: :cascade do |t|
    t.integer "project_id", limit: 4
    t.integer "version_id", limit: 4
  end

  create_table "projects_sops", id: false, force: :cascade do |t|
    t.integer "project_id", limit: 4
    t.integer "sop_id",     limit: 4
  end

  create_table "projects_strains", id: false, force: :cascade do |t|
    t.integer "project_id", limit: 4
    t.integer "strain_id",  limit: 4
  end

  create_table "publication_auth_lookup", id: false, force: :cascade do |t|
    t.integer "user_id",      limit: 4
    t.integer "asset_id",     limit: 4
    t.boolean "can_view",               default: false
    t.boolean "can_manage",             default: false
    t.boolean "can_edit",               default: false
    t.boolean "can_download",           default: false
    t.boolean "can_delete",             default: false
  end

  add_index "publication_auth_lookup", ["user_id", "asset_id", "can_view"], name: "index_pub_user_id_asset_id_can_view", using: :btree
  add_index "publication_auth_lookup", ["user_id", "can_view"], name: "index_publication_auth_lookup_on_user_id_and_can_view", using: :btree

  create_table "publication_authors", force: :cascade do |t|
    t.string   "first_name",     limit: 255
    t.string   "last_name",      limit: 255
    t.integer  "publication_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "author_index",   limit: 4
    t.integer  "person_id",      limit: 4
  end

  create_table "publications", force: :cascade do |t|
    t.integer  "pubmed_id",           limit: 4
    t.text     "title",               limit: 65535
    t.text     "abstract",            limit: 65535
    t.date     "published_date"
    t.string   "journal",             limit: 255
    t.string   "first_letter",        limit: 1
    t.integer  "contributor_id",      limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_used_at"
    t.string   "doi",                 limit: 255
    t.string   "uuid",                limit: 255
    t.integer  "policy_id",           limit: 4
    t.integer  "publication_type",    limit: 4,     default: 1
    t.string   "citation",            limit: 255
    t.string   "deleted_contributor", limit: 255
  end

  add_index "publications", ["contributor_id"], name: "index_publications_on_contributor", using: :btree

  create_table "recommended_model_environments", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reindexing_queues", force: :cascade do |t|
    t.string   "item_type",  limit: 255
    t.integer  "item_id",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "relationship_types", force: :cascade do |t|
    t.string   "title",       limit: 255
    t.text     "description", limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "key",         limit: 255
  end

  create_table "relationships", force: :cascade do |t|
    t.string   "subject_type",      limit: 255, null: false
    t.integer  "subject_id",        limit: 4,   null: false
    t.string   "predicate",         limit: 255, null: false
    t.string   "other_object_type", limit: 255, null: false
    t.integer  "other_object_id",   limit: 4,   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "resource_publish_logs", force: :cascade do |t|
    t.string   "resource_type", limit: 255
    t.integer  "resource_id",   limit: 4
    t.integer  "user_id",       limit: 4
    t.integer  "publish_state", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "comment",       limit: 65535
  end

  add_index "resource_publish_logs", ["publish_state"], name: "index_resource_publish_logs_on_publish_state", using: :btree
  add_index "resource_publish_logs", ["resource_type", "resource_id"], name: "index_resource_publish_logs_on_resource_type_and_resource_id", using: :btree
  add_index "resource_publish_logs", ["user_id"], name: "index_resource_publish_logs_on_user_id", using: :btree

  create_table "sample_attribute_types", force: :cascade do |t|
    t.string   "title",       limit: 255
    t.string   "base_type",   limit: 255
    t.text     "regexp",      limit: 65535
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.string   "placeholder", limit: 255
    t.text     "description", limit: 65535
    t.string   "resolution",  limit: 255
  end

  create_table "sample_attributes", force: :cascade do |t|
    t.string   "title",                      limit: 255
    t.integer  "sample_attribute_type_id",   limit: 4
    t.boolean  "required",                               default: false
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
    t.integer  "pos",                        limit: 4
    t.integer  "sample_type_id",             limit: 4
    t.integer  "unit_id",                    limit: 4
    t.boolean  "is_title",                               default: false
    t.integer  "template_column_index",      limit: 4
    t.string   "accessor_name",              limit: 255
    t.integer  "sample_controlled_vocab_id", limit: 4
    t.integer  "linked_sample_type_id",      limit: 4
  end

  add_index "sample_attributes", ["sample_type_id"], name: "index_sample_attributes_on_sample_type_id", using: :btree
  add_index "sample_attributes", ["unit_id"], name: "index_sample_attributes_on_unit_id", using: :btree

  create_table "sample_auth_lookup", id: false, force: :cascade do |t|
    t.integer "user_id",      limit: 4
    t.integer "asset_id",     limit: 4
    t.boolean "can_view",               default: false
    t.boolean "can_manage",             default: false
    t.boolean "can_edit",               default: false
    t.boolean "can_download",           default: false
    t.boolean "can_delete",             default: false
  end

  add_index "sample_auth_lookup", ["user_id", "asset_id", "can_view"], name: "index_sample_user_id_asset_id_can_view", using: :btree
  add_index "sample_auth_lookup", ["user_id", "can_view"], name: "index_sample_auth_lookup_on_user_id_and_can_view", using: :btree

  create_table "sample_controlled_vocab_terms", force: :cascade do |t|
    t.string   "label",                      limit: 255
    t.integer  "sample_controlled_vocab_id", limit: 4
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
  end

  create_table "sample_controlled_vocabs", force: :cascade do |t|
    t.string   "title",        limit: 255
    t.text     "description",  limit: 65535
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.string   "first_letter", limit: 1
  end

  create_table "sample_resource_links", force: :cascade do |t|
    t.integer "sample_id",     limit: 4
    t.integer "resource_id",   limit: 4
    t.string  "resource_type", limit: 255
  end

  add_index "sample_resource_links", ["resource_id", "resource_type"], name: "index_sample_resource_links_on_resource_id_and_resource_type", using: :btree
  add_index "sample_resource_links", ["sample_id"], name: "index_sample_resource_links_on_sample_id", using: :btree

  create_table "sample_types", force: :cascade do |t|
    t.string   "title",               limit: 255
    t.string   "uuid",                limit: 255
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
    t.string   "first_letter",        limit: 1
    t.text     "description",         limit: 65535
    t.boolean  "uploaded_template",                 default: false
    t.integer  "contributor_id",      limit: 4
    t.string   "deleted_contributor", limit: 255
  end

  create_table "samples", force: :cascade do |t|
    t.string   "title",                    limit: 255
    t.integer  "sample_type_id",           limit: 4
    t.text     "json_metadata",            limit: 65535
    t.string   "uuid",                     limit: 255
    t.integer  "contributor_id",           limit: 4
    t.integer  "policy_id",                limit: 4
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.string   "first_letter",             limit: 1
    t.text     "other_creators",           limit: 65535
    t.integer  "originating_data_file_id", limit: 4
    t.string   "deleted_contributor",      limit: 255
  end

  create_table "saved_searches", force: :cascade do |t|
    t.integer  "user_id",                 limit: 4
    t.text     "search_query",            limit: 65535
    t.text     "search_type",             limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "include_external_search",               default: false
  end

  create_table "scales", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.string   "key",        limit: 255
    t.integer  "pos",        limit: 4,   default: 1
    t.string   "image_name", limit: 255
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
  end

  create_table "scalings", force: :cascade do |t|
    t.integer  "scale_id",      limit: 4
    t.integer  "scalable_id",   limit: 4
    t.integer  "person_id",     limit: 4
    t.string   "scalable_type", limit: 255
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255,   null: false
    t.text     "data",       limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "settings", force: :cascade do |t|
    t.string   "var",                limit: 255,   null: false
    t.text     "value",              limit: 65535
    t.integer  "target_id",          limit: 4
    t.string   "target_type",        limit: 30
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "encrypted_value",    limit: 65535
    t.string   "encrypted_value_iv", limit: 255
  end

  add_index "settings", ["target_type", "target_id", "var"], name: "index_settings_on_target_type_and_target_id_and_var", unique: true, using: :btree

  create_table "site_announcement_categories", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.string   "icon_key",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "site_announcements", force: :cascade do |t|
    t.integer  "announcer_id",                  limit: 4
    t.string   "announcer_type",                limit: 255
    t.string   "title",                         limit: 255
    t.text     "body",                          limit: 65535
    t.integer  "site_announcement_category_id", limit: 4
    t.boolean  "is_headline",                                 default: false
    t.datetime "expires_at"
    t.boolean  "show_in_feed",                                default: true
    t.boolean  "email_notification",                          default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "snapshots", force: :cascade do |t|
    t.string   "resource_type",        limit: 255
    t.integer  "resource_id",          limit: 4
    t.string   "doi",                  limit: 255
    t.integer  "snapshot_number",      limit: 4
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.integer  "zenodo_deposition_id", limit: 4
    t.string   "zenodo_record_url",    limit: 255
  end

  create_table "sop_auth_lookup", id: false, force: :cascade do |t|
    t.integer "user_id",      limit: 4
    t.integer "asset_id",     limit: 4
    t.boolean "can_view",               default: false
    t.boolean "can_manage",             default: false
    t.boolean "can_edit",               default: false
    t.boolean "can_download",           default: false
    t.boolean "can_delete",             default: false
  end

  add_index "sop_auth_lookup", ["user_id", "asset_id", "can_view"], name: "index_sop_auth_lookup_on_user_id_and_asset_id_and_can_view", using: :btree
  add_index "sop_auth_lookup", ["user_id", "can_view"], name: "index_sop_auth_lookup_on_user_id_and_can_view", using: :btree

  create_table "sop_deprecated_specimens", force: :cascade do |t|
    t.integer "deprecated_specimen_id", limit: 4
    t.integer "sop_id",                 limit: 4
    t.integer "sop_version",            limit: 4
  end

  create_table "sop_versions", force: :cascade do |t|
    t.integer  "sop_id",              limit: 4
    t.integer  "version",             limit: 4
    t.text     "revision_comments",   limit: 65535
    t.integer  "contributor_id",      limit: 4
    t.string   "title",               limit: 255
    t.text     "description",         limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_used_at"
    t.string   "first_letter",        limit: 1
    t.text     "other_creators",      limit: 65535
    t.string   "uuid",                limit: 255
    t.integer  "policy_id",           limit: 4
    t.string   "doi",                 limit: 255
    t.string   "license",             limit: 255
    t.string   "deleted_contributor", limit: 255
  end

  add_index "sop_versions", ["contributor_id"], name: "index_sop_versions_on_contributor", using: :btree
  add_index "sop_versions", ["sop_id"], name: "index_sop_versions_on_sop_id", using: :btree

  create_table "sops", force: :cascade do |t|
    t.integer  "contributor_id",      limit: 4
    t.string   "title",               limit: 255
    t.text     "description",         limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_used_at"
    t.integer  "version",             limit: 4,     default: 1
    t.string   "first_letter",        limit: 1
    t.text     "other_creators",      limit: 65535
    t.string   "uuid",                limit: 255
    t.integer  "policy_id",           limit: 4
    t.string   "doi",                 limit: 255
    t.string   "license",             limit: 255
    t.string   "deleted_contributor", limit: 255
  end

  add_index "sops", ["contributor_id"], name: "index_sops_on_contributor", using: :btree

  create_table "special_auth_codes", force: :cascade do |t|
    t.string   "code",            limit: 255
    t.date     "expiration_date"
    t.string   "asset_type",      limit: 255
    t.integer  "asset_id",        limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "strain_auth_lookup", id: false, force: :cascade do |t|
    t.integer "user_id",      limit: 4
    t.integer "asset_id",     limit: 4
    t.boolean "can_view",               default: false
    t.boolean "can_manage",             default: false
    t.boolean "can_edit",               default: false
    t.boolean "can_download",           default: false
    t.boolean "can_delete",             default: false
  end

  add_index "strain_auth_lookup", ["user_id", "asset_id", "can_view"], name: "index_strain_user_id_asset_id_can_view", using: :btree
  add_index "strain_auth_lookup", ["user_id", "can_view"], name: "index_strain_auth_lookup_on_user_id_and_can_view", using: :btree

  create_table "strain_descendants", id: false, force: :cascade do |t|
    t.integer "ancestor_id",   limit: 4
    t.integer "descendant_id", limit: 4
  end

  create_table "strains", force: :cascade do |t|
    t.string   "title",               limit: 255
    t.integer  "organism_id",         limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id",           limit: 4
    t.string   "synonym",             limit: 255
    t.text     "comment",             limit: 65535
    t.string   "provider_id",         limit: 255
    t.string   "provider_name",       limit: 255
    t.boolean  "is_dummy",                          default: false
    t.integer  "contributor_id",      limit: 4
    t.integer  "policy_id",           limit: 4
    t.string   "uuid",                limit: 255
    t.string   "first_letter",        limit: 255
    t.string   "deleted_contributor", limit: 255
  end

  create_table "studied_factor_links", force: :cascade do |t|
    t.string   "substance_type",    limit: 255
    t.integer  "substance_id",      limit: 4
    t.integer  "studied_factor_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "studied_factors", force: :cascade do |t|
    t.integer  "measured_item_id",   limit: 4
    t.float    "start_value",        limit: 24
    t.float    "end_value",          limit: 24
    t.integer  "unit_id",            limit: 4
    t.float    "time_point",         limit: 24
    t.integer  "data_file_id",       limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "standard_deviation", limit: 24
    t.integer  "data_file_version",  limit: 4
  end

  add_index "studied_factors", ["data_file_id"], name: "index_studied_factors_on_data_file_id", using: :btree

  create_table "studies", force: :cascade do |t|
    t.string   "title",                 limit: 255
    t.text     "description",           limit: 65535
    t.integer  "investigation_id",      limit: 4
    t.text     "experimentalists",      limit: 65535
    t.datetime "begin_date"
    t.integer  "person_responsible_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_letter",          limit: 1
    t.string   "uuid",                  limit: 255
    t.integer  "policy_id",             limit: 4
    t.integer  "contributor_id",        limit: 4
    t.text     "other_creators",        limit: 65535
    t.string   "deleted_contributor",   limit: 255
  end

  create_table "study_auth_lookup", id: false, force: :cascade do |t|
    t.integer "user_id",      limit: 4
    t.integer "asset_id",     limit: 4
    t.boolean "can_view",               default: false
    t.boolean "can_manage",             default: false
    t.boolean "can_edit",               default: false
    t.boolean "can_download",           default: false
    t.boolean "can_delete",             default: false
  end

  add_index "study_auth_lookup", ["user_id", "asset_id", "can_view"], name: "index_study_auth_lookup_on_user_id_and_asset_id_and_can_view", using: :btree
  add_index "study_auth_lookup", ["user_id", "can_view"], name: "index_study_auth_lookup_on_user_id_and_can_view", using: :btree

  create_table "subscriptions", force: :cascade do |t|
    t.integer  "person_id",               limit: 4
    t.integer  "subscribable_id",         limit: 4
    t.string   "subscribable_type",       limit: 255
    t.string   "subscription_type",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "project_subscription_id", limit: 4
  end

  create_table "suggested_assay_types", force: :cascade do |t|
    t.string   "label",          limit: 255
    t.string   "ontology_uri",   limit: 255
    t.integer  "contributor_id", limit: 4
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.integer  "parent_id",      limit: 4
  end

  create_table "suggested_technology_types", force: :cascade do |t|
    t.string   "label",          limit: 255
    t.string   "ontology_uri",   limit: 255
    t.integer  "contributor_id", limit: 4
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.integer  "parent_id",      limit: 4
  end

  create_table "synonyms", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.integer  "substance_id",   limit: 4
    t.string   "substance_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "synonyms", ["substance_id", "substance_type"], name: "index_synonyms_on_substance_id_and_substance_type", using: :btree

  create_table "taggings", force: :cascade do |t|
    t.integer  "tag_id",        limit: 4
    t.integer  "taggable_id",   limit: 4
    t.integer  "tagger_id",     limit: 4
    t.string   "tagger_type",   limit: 255
    t.string   "taggable_type", limit: 255
    t.string   "context",       limit: 255
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], name: "index_taggings_on_tag_id", using: :btree
  add_index "taggings", ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context", using: :btree

  create_table "tags", force: :cascade do |t|
    t.string "name", limit: 255
  end

  create_table "text_value_versions", force: :cascade do |t|
    t.integer  "text_value_id",      limit: 4,        null: false
    t.integer  "version",            limit: 4,        null: false
    t.integer  "version_creator_id", limit: 4
    t.text     "text",               limit: 16777215, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "text_value_versions", ["text_value_id"], name: "index_text_value_versions_on_text_value_id", using: :btree

  create_table "text_values", force: :cascade do |t|
    t.integer  "version",            limit: 4
    t.integer  "version_creator_id", limit: 4
    t.text     "text",               limit: 16777215, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tissue_and_cell_types", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "units", force: :cascade do |t|
    t.string   "title",           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "symbol",          limit: 255
    t.string   "comment",         limit: 255
    t.boolean  "factors_studied",             default: true
    t.integer  "order",           limit: 4
  end

  create_table "users", force: :cascade do |t|
    t.string   "login",                     limit: 255
    t.string   "crypted_password",          limit: 64
    t.string   "salt",                      limit: 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token",            limit: 255
    t.datetime "remember_token_expires_at"
    t.string   "activation_code",           limit: 40
    t.datetime "activated_at"
    t.integer  "person_id",                 limit: 4
    t.string   "reset_password_code",       limit: 255
    t.datetime "reset_password_code_until"
    t.integer  "posts_count",               limit: 4,   default: 0
    t.datetime "last_seen_at"
    t.string   "uuid",                      limit: 255
  end

  create_table "work_groups", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.integer  "institution_id", limit: 4
    t.integer  "project_id",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "work_groups", ["project_id"], name: "index_work_groups_on_project_id", using: :btree

  create_table "worksheets", force: :cascade do |t|
    t.integer "content_blob_id", limit: 4
    t.integer "last_row",        limit: 4
    t.integer "last_column",     limit: 4
    t.integer "sheet_number",    limit: 4
  end

end
