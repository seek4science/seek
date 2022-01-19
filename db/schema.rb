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

ActiveRecord::Schema.define(version: 2021_12_09_112856) do

  create_table "activity_logs", id: :integer,  force: :cascade do |t|
    t.string "action"
    t.string "format"
    t.string "activity_loggable_type"
    t.integer "activity_loggable_id"
    t.string "culprit_type"
    t.integer "culprit_id"
    t.string "referenced_type"
    t.integer "referenced_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "http_referer"
    t.text "user_agent"
    t.text "data", limit: 16777215
    t.string "controller_name"
    t.index ["action"], name: "act_logs_action_index"
    t.index ["activity_loggable_type", "activity_loggable_id"], name: "act_logs_act_loggable_index"
    t.index ["culprit_type", "culprit_id"], name: "act_logs_culprit_index"
    t.index ["format"], name: "act_logs_format_index"
    t.index ["referenced_type", "referenced_id"], name: "act_logs_referenced_index"
  end

  create_table "admin_defined_role_programmes", id: :integer,  force: :cascade do |t|
    t.integer "programme_id"
    t.integer "person_id"
    t.integer "role_mask"
  end

  create_table "admin_defined_role_projects", id: :integer,  force: :cascade do |t|
    t.integer "project_id"
    t.integer "role_mask"
    t.integer "person_id"
  end

  create_table "annotation_attributes", id: :integer,  force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "identifier", null: false
    t.index ["name"], name: "index_annotation_attributes_on_name"
  end

  create_table "annotation_value_seeds", id: :integer,  force: :cascade do |t|
    t.integer "attribute_id", null: false
    t.string "old_value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "value_type", limit: 50, default: "FIXME", null: false
    t.integer "value_id", default: 0, null: false
    t.index ["attribute_id"], name: "index_annotation_value_seeds_on_attribute_id"
  end

  create_table "annotation_versions", id: :integer,  force: :cascade do |t|
    t.integer "annotation_id", null: false
    t.integer "version", null: false
    t.integer "version_creator_id"
    t.string "source_type", null: false
    t.integer "source_id", null: false
    t.string "annotatable_type", limit: 50, null: false
    t.integer "annotatable_id", null: false
    t.integer "attribute_id", null: false
    t.string "old_value", default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "value_type", limit: 50, default: "FIXME", null: false
    t.integer "value_id", default: 0, null: false
    t.index ["annotation_id"], name: "index_annotation_versions_on_annotation_id"
  end

  create_table "annotations", id: :integer,  force: :cascade do |t|
    t.string "source_type", null: false
    t.integer "source_id", null: false
    t.string "annotatable_type", limit: 50, null: false
    t.integer "annotatable_id", null: false
    t.integer "attribute_id", null: false
    t.string "old_value", default: ""
    t.integer "version"
    t.integer "version_creator_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "value_type", limit: 50, default: "FIXME", null: false
    t.integer "value_id", default: 0, null: false
    t.index ["annotatable_type", "annotatable_id"], name: "index_annotations_on_annotatable_type_and_annotatable_id"
    t.index ["attribute_id"], name: "index_annotations_on_attribute_id"
    t.index ["source_type", "source_id"], name: "index_annotations_on_source_type_and_source_id"
    t.index ["value_type", "value_id"], name: "index_annotations_on_value_type_and_value_id"
  end

  create_table "api_tokens",  force: :cascade do |t|
    t.bigint "user_id"
    t.string "title"
    t.string "encrypted_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["encrypted_token"], name: "index_api_tokens_on_encrypted_token"
    t.index ["user_id"], name: "index_api_tokens_on_user_id"
  end

  create_table "application_status",  force: :cascade do |t|
    t.integer "running_jobs"
    t.boolean "soffice_running"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "assay_assets", id: :integer,  force: :cascade do |t|
    t.integer "assay_id"
    t.integer "asset_id"
    t.integer "version"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "relationship_type_id"
    t.string "asset_type"
    t.integer "direction", default: 0
    t.index ["assay_id"], name: "index_assay_assets_on_assay_id"
    t.index ["asset_id", "asset_type"], name: "index_assay_assets_on_asset_id_and_asset_type"
  end

  create_table "assay_auth_lookup",  force: :cascade do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view", default: false
    t.boolean "can_manage", default: false
    t.boolean "can_edit", default: false
    t.boolean "can_download", default: false
    t.boolean "can_delete", default: false
    t.index ["user_id", "asset_id", "can_view"], name: "index_assay_auth_lookup_on_user_id_and_asset_id_and_can_view"
    t.index ["user_id", "can_view"], name: "index_assay_auth_lookup_on_user_id_and_can_view"
  end

  create_table "assay_classes", id: :integer,  force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "key", limit: 10
  end

  create_table "assay_human_diseases", id: :integer,  force: :cascade do |t|
    t.integer "assay_id"
    t.integer "human_disease_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["assay_id"], name: "index_assay_diseases_on_assay_id"
    t.index ["human_disease_id"], name: "index_assay_diseases_on_disease_id"
  end

  create_table "assay_organisms", id: :integer,  force: :cascade do |t|
    t.integer "assay_id"
    t.integer "organism_id"
    t.integer "culture_growth_type_id"
    t.integer "strain_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "tissue_and_cell_type_id"
    t.index ["assay_id"], name: "index_assay_organisms_on_assay_id"
    t.index ["organism_id"], name: "index_assay_organisms_on_organism_id"
  end

  create_table "assays", id: :integer,  force: :cascade do |t|
    t.text "title"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "study_id"
    t.integer "contributor_id"
    t.string "first_letter", limit: 1
    t.integer "assay_class_id"
    t.string "uuid"
    t.integer "policy_id"
    t.integer "institution_id"
    t.string "assay_type_uri"
    t.string "technology_type_uri"
    t.integer "suggested_assay_type_id"
    t.integer "suggested_technology_type_id"
    t.text "other_creators"
    t.string "deleted_contributor"
    t.integer "sample_type_id"
    t.integer "position"
    t.index ["sample_type_id"], name: "index_assays_on_sample_type_id"
  end

  create_table "asset_doi_logs", id: :integer,  force: :cascade do |t|
    t.string "asset_type"
    t.integer "asset_id"
    t.integer "asset_version"
    t.integer "action"
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "doi"
  end

  create_table "asset_links",  force: :cascade do |t|
    t.integer "asset_id"
    t.string "asset_type"
    t.text "url"
    t.string "link_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "label"
    t.index ["asset_id", "asset_type"], name: "index_asset_links_on_asset_id_and_asset_type"
  end

  create_table "assets", id: :integer,  force: :cascade do |t|
    t.integer "project_id"
    t.string "resource_type"
    t.integer "resource_id"
    t.integer "policy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_used_at"
  end

  create_table "assets_creators", id: :integer,  force: :cascade do |t|
    t.integer "asset_id"
    t.integer "creator_id"
    t.string "asset_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "pos", default: 0
    t.string "family_name"
    t.string "given_name"
    t.string "orcid"
    t.text "affiliation"
    t.index ["asset_id", "asset_type"], name: "index_assets_creators_on_asset_id_and_asset_type"
  end

  create_table "auth_lookup_update_queues", id: :integer,  force: :cascade do |t|
    t.integer "item_id"
    t.string "item_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "priority", default: 0
    t.index ["item_id", "item_type"], name: "index_auth_lookup_update_queues_on_item_id_and_item_type"
  end

  create_table "avatars", id: :integer,  force: :cascade do |t|
    t.string "owner_type"
    t.integer "owner_id"
    t.string "original_filename"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["owner_type", "owner_id"], name: "index_avatars_on_owner_type_and_owner_id"
  end

  create_table "bioportal_concepts", id: :integer,  force: :cascade do |t|
    t.string "ontology_id"
    t.string "concept_uri"
    t.text "cached_concept_yaml"
    t.integer "conceptable_id"
    t.string "conceptable_type"
  end

  create_table "cell_ranges", id: :integer,  force: :cascade do |t|
    t.integer "cell_range_id"
    t.integer "worksheet_id"
    t.integer "start_row"
    t.integer "start_column"
    t.integer "end_row"
    t.integer "end_column"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "collection_auth_lookup",  force: :cascade do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view", default: false
    t.boolean "can_manage", default: false
    t.boolean "can_edit", default: false
    t.boolean "can_download", default: false
    t.boolean "can_delete", default: false
    t.index ["user_id", "asset_id", "can_view"], name: "index_collection_user_id_asset_id_can_view"
    t.index ["user_id", "can_view"], name: "index_collection_auth_lookup_on_user_id_and_can_view"
  end

  create_table "collection_items",  force: :cascade do |t|
    t.bigint "collection_id"
    t.string "asset_type"
    t.bigint "asset_id"
    t.text "comment"
    t.integer "order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_type", "asset_id"], name: "index_collection_items_on_asset_type_and_asset_id"
    t.index ["collection_id"], name: "index_collection_items_on_collection_id"
  end

  create_table "collections",  force: :cascade do |t|
    t.text "title"
    t.text "description"
    t.bigint "contributor_id"
    t.string "first_letter", limit: 1
    t.string "uuid"
    t.bigint "policy_id"
    t.string "doi"
    t.string "license"
    t.datetime "last_used_at"
    t.text "other_creators"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "avatar_id"
    t.index ["avatar_id"], name: "index_collections_on_avatar_id"
    t.index ["contributor_id"], name: "index_collections_on_contributor_id"
    t.index ["policy_id"], name: "index_collections_on_policy_id"
  end

  create_table "collections_projects",  force: :cascade do |t|
    t.bigint "collection_id"
    t.bigint "project_id"
    t.index ["collection_id", "project_id"], name: "index_collections_projects_on_collection_id_and_project_id"
    t.index ["collection_id"], name: "index_collections_projects_on_collection_id"
    t.index ["project_id"], name: "index_collections_projects_on_project_id"
  end

  create_table "compounds", id: :integer,  force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "content_blobs", id: :integer,  force: :cascade do |t|
    t.string "md5sum"
    t.text "url"
    t.string "uuid"
    t.string "original_filename"
    t.string "content_type"
    t.integer "asset_id"
    t.string "asset_type"
    t.integer "asset_version"
    t.boolean "is_webpage", default: false
    t.boolean "external_link"
    t.string "sha1sum"
    t.bigint "file_size"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["asset_id", "asset_type"], name: "index_content_blobs_on_asset_id_and_asset_type"
  end

  create_table "culture_growth_types", id: :integer,  force: :cascade do |t|
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cultures", id: :integer,  force: :cascade do |t|
    t.integer "organism_id"
    t.integer "sop_id"
    t.datetime "date_at_sampling"
    t.datetime "culture_start_date"
    t.integer "age_at_sampling"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "custom_metadata",  force: :cascade do |t|
    t.text "json_metadata"
    t.string "item_type"
    t.bigint "item_id"
    t.bigint "custom_metadata_type_id"
    t.index ["custom_metadata_type_id"], name: "index_custom_metadata_on_custom_metadata_type_id"
    t.index ["item_type", "item_id"], name: "index_custom_metadata_on_item_type_and_item_id"
  end

  create_table "custom_metadata_attributes",  force: :cascade do |t|
    t.bigint "custom_metadata_type_id"
    t.bigint "sample_attribute_type_id"
    t.boolean "required", default: false
    t.integer "pos"
    t.string "title"
    t.bigint "sample_controlled_vocab_id"
    t.text "description"
    t.string "label"
    t.index ["custom_metadata_type_id"], name: "index_custom_metadata_attributes_on_custom_metadata_type_id"
    t.index ["sample_attribute_type_id"], name: "index_custom_metadata_attributes_on_sample_attribute_type_id"
    t.index ["sample_controlled_vocab_id"], name: "index_custom_metadata_attributes_on_sample_controlled_vocab_id"
  end

  create_table "custom_metadata_types",  force: :cascade do |t|
    t.string "title"
    t.integer "contributor_id"
    t.text "supported_type"
  end

  create_table "data_file_auth_lookup",  force: :cascade do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view", default: false
    t.boolean "can_manage", default: false
    t.boolean "can_edit", default: false
    t.boolean "can_download", default: false
    t.boolean "can_delete", default: false
    t.index ["user_id", "asset_id", "can_view"], name: "index_data_file_auth_lookup_user_asset_view"
    t.index ["user_id", "can_view"], name: "index_data_file_auth_lookup_on_user_id_and_can_view"
  end

  create_table "data_file_versions", id: :integer,  force: :cascade do |t|
    t.integer "data_file_id"
    t.integer "version"
    t.text "revision_comments"
    t.integer "contributor_id"
    t.string "title"
    t.text "description"
    t.integer "template_id"
    t.datetime "last_used_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "first_letter", limit: 1
    t.text "other_creators"
    t.string "uuid"
    t.integer "policy_id"
    t.string "doi"
    t.string "license"
    t.boolean "simulation_data", default: false
    t.string "deleted_contributor"
    t.integer "visibility"
    t.index ["contributor_id"], name: "index_data_file_versions_contributor"
    t.index ["data_file_id"], name: "index_data_file_versions_on_data_file_id"
  end

  create_table "data_file_versions_projects", id: false,  force: :cascade do |t|
    t.integer "project_id"
    t.integer "version_id"
  end

  create_table "data_files", id: :integer,  force: :cascade do |t|
    t.integer "contributor_id"
    t.string "title"
    t.text "description"
    t.integer "template_id"
    t.datetime "last_used_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "version", default: 1
    t.string "first_letter", limit: 1
    t.text "other_creators"
    t.string "uuid"
    t.integer "policy_id"
    t.string "doi"
    t.string "license"
    t.boolean "simulation_data", default: false
    t.string "deleted_contributor"
    t.index ["contributor_id"], name: "index_data_files_on_contributor"
  end

  create_table "data_files_events", id: false,  force: :cascade do |t|
    t.integer "data_file_id"
    t.integer "event_id"
  end

  create_table "data_files_projects", id: false,  force: :cascade do |t|
    t.integer "project_id"
    t.integer "data_file_id"
    t.index ["data_file_id", "project_id"], name: "index_data_files_projects_on_data_file_id_and_project_id"
    t.index ["project_id"], name: "index_data_files_projects_on_project_id"
  end

  create_table "db_files", id: :integer,  force: :cascade do |t|
    t.binary "data"
  end

  create_table "delayed_jobs", id: :integer,  force: :cascade do |t|
    t.integer "priority", default: 0
    t.integer "attempts", default: 0
    t.text "handler"
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "disciplines", id: :integer,  force: :cascade do |t|
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "disciplines_people", id: false,  force: :cascade do |t|
    t.integer "discipline_id"
    t.integer "person_id"
    t.index ["person_id"], name: "index_disciplines_people_on_person_id"
  end

  create_table "document_auth_lookup",  force: :cascade do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view", default: false
    t.boolean "can_manage", default: false
    t.boolean "can_edit", default: false
    t.boolean "can_download", default: false
    t.boolean "can_delete", default: false
    t.index ["user_id", "asset_id", "can_view"], name: "index_document_user_id_asset_id_can_view"
    t.index ["user_id", "can_view"], name: "index_document_auth_lookup_on_user_id_and_can_view"
  end

  create_table "document_versions", id: :integer,  force: :cascade do |t|
    t.integer "document_id"
    t.integer "version"
    t.text "revision_comments"
    t.text "title"
    t.text "description"
    t.integer "contributor_id"
    t.string "first_letter", limit: 1
    t.string "uuid"
    t.integer "policy_id"
    t.string "doi"
    t.string "license"
    t.datetime "last_used_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "other_creators"
    t.string "deleted_contributor"
    t.integer "visibility"
    t.index ["contributor_id"], name: "index_document_versions_on_contributor"
    t.index ["document_id"], name: "index_document_versions_on_document_id"
  end

  create_table "document_versions_projects", id: :integer,  force: :cascade do |t|
    t.integer "version_id"
    t.integer "project_id"
    t.index ["project_id"], name: "index_document_versions_projects_on_project_id"
    t.index ["version_id", "project_id"], name: "index_document_versions_projects_on_version_id_and_project_id"
  end

  create_table "documents", id: :integer,  force: :cascade do |t|
    t.text "title"
    t.text "description"
    t.integer "contributor_id"
    t.integer "version"
    t.string "first_letter", limit: 1
    t.string "uuid"
    t.integer "policy_id"
    t.string "doi"
    t.string "license"
    t.datetime "last_used_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "other_creators"
    t.string "deleted_contributor"
    t.index ["contributor_id"], name: "index_documents_on_contributor"
  end

  create_table "documents_events", id: false,  force: :cascade do |t|
    t.integer "document_id", null: false
    t.integer "event_id", null: false
    t.index ["document_id", "event_id"], name: "index_documents_events_on_document_id_and_event_id"
    t.index ["event_id", "document_id"], name: "index_documents_events_on_event_id_and_document_id"
  end

  create_table "documents_projects", id: :integer,  force: :cascade do |t|
    t.integer "document_id"
    t.integer "project_id"
    t.index ["document_id", "project_id"], name: "index_documents_projects_on_document_id_and_project_id"
    t.index ["project_id"], name: "index_documents_projects_on_project_id"
  end

  create_table "documents_workflows", id: false,  force: :cascade do |t|
    t.bigint "workflow_id", null: false
    t.bigint "document_id", null: false
    t.index ["document_id", "workflow_id"], name: "index_documents_workflows_on_doc_workflow"
    t.index ["workflow_id", "document_id"], name: "index_documents_workflows_on_workflow_doc"
  end

  create_table "event_auth_lookup",  force: :cascade do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view", default: false
    t.boolean "can_manage", default: false
    t.boolean "can_edit", default: false
    t.boolean "can_download", default: false
    t.boolean "can_delete", default: false
    t.index ["user_id", "asset_id", "can_view"], name: "index_event_auth_lookup_on_user_id_and_asset_id_and_can_view"
    t.index ["user_id", "can_view"], name: "index_event_auth_lookup_on_user_id_and_can_view"
  end

  create_table "events", id: :integer,  force: :cascade do |t|
    t.datetime "start_date"
    t.datetime "end_date"
    t.text "address"
    t.string "city"
    t.string "country"
    t.text "url"
    t.text "description"
    t.string "title"
    t.integer "policy_id"
    t.integer "contributor_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "first_letter", limit: 1
    t.string "uuid"
    t.string "deleted_contributor"
  end

  create_table "events_presentations", id: false,  force: :cascade do |t|
    t.integer "presentation_id"
    t.integer "event_id"
  end

  create_table "events_projects", id: false,  force: :cascade do |t|
    t.integer "project_id"
    t.integer "event_id"
    t.index ["event_id", "project_id"], name: "index_events_projects_on_event_id_and_project_id"
    t.index ["project_id"], name: "index_events_projects_on_project_id"
  end

  create_table "events_publications", id: false,  force: :cascade do |t|
    t.integer "publication_id"
    t.integer "event_id"
  end

  create_table "experimental_condition_links", id: :integer,  force: :cascade do |t|
    t.string "substance_type"
    t.integer "substance_id"
    t.integer "experimental_condition_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "experimental_conditions", id: :integer,  force: :cascade do |t|
    t.integer "measured_item_id"
    t.float "start_value"
    t.float "end_value"
    t.integer "unit_id"
    t.integer "sop_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "sop_version"
    t.index ["sop_id"], name: "index_experimental_conditions_on_sop_id"
  end

  create_table "external_assets", id: :integer,  force: :cascade do |t|
    t.string "external_service", null: false
    t.string "external_id", null: false
    t.string "external_mod_stamp"
    t.string "external_type"
    t.datetime "synchronized_at"
    t.integer "sync_state", limit: 1, default: 0, null: false
    t.text "sync_options_json"
    t.integer "version", default: 0, null: false
    t.integer "seek_entity_id"
    t.string "seek_entity_type"
    t.integer "seek_service_id"
    t.string "seek_service_type"
    t.string "class_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "err_msg"
    t.integer "failures", default: 0
    t.index ["seek_entity_type", "seek_entity_id"], name: "index_external_assets_on_seek_entity_type_and_seek_entity_id"
    t.index ["seek_service_type", "seek_service_id"], name: "index_external_assets_on_seek_service_type_and_seek_service_id"
  end

  create_table "favourite_group_memberships", id: :integer,  force: :cascade do |t|
    t.integer "person_id"
    t.integer "favourite_group_id"
    t.integer "access_type", limit: 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "favourite_groups", id: :integer,  force: :cascade do |t|
    t.integer "user_id"
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "favourites", id: :integer,  force: :cascade do |t|
    t.integer "resource_id"
    t.integer "user_id"
    t.string "resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "genes", id: :integer,  force: :cascade do |t|
    t.string "title"
    t.string "symbol"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "genotypes", id: :integer,  force: :cascade do |t|
    t.integer "gene_id"
    t.integer "modification_id"
    t.integer "strain_id"
    t.text "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "group_memberships", id: :integer,  force: :cascade do |t|
    t.integer "person_id"
    t.integer "work_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "time_left_at"
    t.boolean "has_left", default: false
    t.index ["person_id"], name: "index_group_memberships_on_person_id"
    t.index ["work_group_id", "person_id"], name: "index_group_memberships_on_work_group_id_and_person_id"
    t.index ["work_group_id"], name: "index_group_memberships_on_work_group_id"
  end

  create_table "group_memberships_project_positions", id: :integer,  force: :cascade do |t|
    t.integer "group_membership_id"
    t.integer "project_position_id"
  end

  create_table "help_attachments", id: :integer,  force: :cascade do |t|
    t.integer "help_document_id"
    t.string "title"
    t.string "content_type"
    t.string "filename"
    t.integer "size"
    t.integer "db_file_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "help_documents", id: :integer,  force: :cascade do |t|
    t.string "identifier"
    t.string "title"
    t.text "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "help_images", id: :integer,  force: :cascade do |t|
    t.integer "help_document_id"
    t.string "content_type"
    t.string "filename"
    t.integer "size"
    t.integer "height"
    t.integer "width"
    t.integer "parent_id"
    t.string "thumbnail"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "human_disease_parents", id: false,  force: :cascade do |t|
    t.integer "human_disease_id"
    t.integer "parent_id"
    t.index ["human_disease_id", "parent_id"], name: "index_disease_parents_on_disease_id_and_parent_id"
    t.index ["parent_id"], name: "index_disease_parents_on_parent_id"
  end

  create_table "human_diseases", id: :integer,  force: :cascade do |t|
    t.string "title"
    t.string "doid_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "first_letter"
    t.string "uuid"
  end

  create_table "human_diseases_projects", id: false,  force: :cascade do |t|
    t.integer "human_disease_id"
    t.integer "project_id"
    t.index ["human_disease_id", "project_id"], name: "index_diseases_projects_on_disease_id_and_project_id"
    t.index ["project_id"], name: "index_diseases_projects_on_project_id"
  end

  create_table "human_diseases_publications", id: false,  force: :cascade do |t|
    t.integer "human_disease_id"
    t.integer "publication_id"
    t.index ["human_disease_id", "publication_id"], name: "index_diseases_publications_on_disease_id_and_publication_id"
    t.index ["publication_id"], name: "index_diseases_publications_on_publication_id"
  end

  create_table "identities", id: :integer,  force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider"
    t.string "uid"
    t.integer "user_id"
    t.index ["provider", "uid"], name: "index_identities_on_provider_and_uid"
    t.index ["user_id"], name: "index_identities_on_user_id"
  end

  create_table "institutions", id: :integer,  force: :cascade do |t|
    t.string "title"
    t.text "address"
    t.string "city"
    t.text "web_page"
    t.string "country"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "avatar_id"
    t.string "first_letter", limit: 1
    t.string "uuid"
  end

  create_table "investigation_auth_lookup",  force: :cascade do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view", default: false
    t.boolean "can_manage", default: false
    t.boolean "can_edit", default: false
    t.boolean "can_download", default: false
    t.boolean "can_delete", default: false
    t.index ["user_id", "asset_id", "can_view"], name: "index_inv_user_id_asset_id_can_view"
    t.index ["user_id", "can_view"], name: "index_investigation_auth_lookup_on_user_id_and_can_view"
  end

  create_table "investigations", id: :integer,  force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "first_letter", limit: 1
    t.string "uuid"
    t.integer "policy_id"
    t.integer "contributor_id"
    t.text "other_creators"
    t.string "deleted_contributor"
    t.integer "position"
  end

  create_table "investigations_projects", id: false,  force: :cascade do |t|
    t.integer "project_id"
    t.integer "investigation_id"
    t.index ["investigation_id", "project_id"], name: "index_investigations_projects_inv_proj_id"
    t.index ["project_id"], name: "index_investigations_projects_on_project_id"
  end

  create_table "isa_tags",  force: :cascade do |t|
    t.string "title"
    t.index ["title"], name: "index_isa_tags_title"
  end

  create_table "mapping_links", id: :integer,  force: :cascade do |t|
    t.string "substance_type"
    t.integer "substance_id"
    t.integer "mapping_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mappings", id: :integer,  force: :cascade do |t|
    t.integer "sabiork_id"
    t.string "chebi_id"
    t.string "kegg_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "measured_items", id: :integer,  force: :cascade do |t|
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "factors_studied", default: true
  end

  create_table "message_logs", id: :integer,  force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "message_type"
    t.text "details"
    t.integer "subject_id"
    t.string "subject_type"
    t.integer "sender_id"
    t.text "response"
    t.index ["sender_id"], name: "index_message_logs_on_sender_id"
    t.index ["subject_type", "subject_id"], name: "index_message_logs_on_subject_type_and_subject_id"
  end

  create_table "model_auth_lookup",  force: :cascade do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view", default: false
    t.boolean "can_manage", default: false
    t.boolean "can_edit", default: false
    t.boolean "can_download", default: false
    t.boolean "can_delete", default: false
    t.index ["user_id", "asset_id", "can_view"], name: "index_model_auth_lookup_on_user_id_and_asset_id_and_can_view"
    t.index ["user_id", "can_view"], name: "index_model_auth_lookup_on_user_id_and_can_view"
  end

  create_table "model_formats", id: :integer,  force: :cascade do |t|
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "model_images", id: :integer,  force: :cascade do |t|
    t.integer "model_id"
    t.string "original_filename"
    t.string "content_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "image_width"
    t.integer "image_height"
  end

  create_table "model_types", id: :integer,  force: :cascade do |t|
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "model_versions", id: :integer,  force: :cascade do |t|
    t.integer "model_id"
    t.integer "version"
    t.text "revision_comments"
    t.integer "contributor_id"
    t.string "title"
    t.text "description"
    t.integer "recommended_environment_id"
    t.datetime "last_used_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "organism_id"
    t.integer "model_type_id"
    t.integer "model_format_id"
    t.string "first_letter", limit: 1
    t.text "other_creators"
    t.string "uuid"
    t.integer "policy_id"
    t.string "imported_source"
    t.string "imported_url"
    t.integer "model_image_id"
    t.string "doi"
    t.string "license"
    t.string "deleted_contributor"
    t.integer "human_disease_id"
    t.integer "visibility"
    t.index ["contributor_id"], name: "index_model_versions_on_contributor"
    t.index ["model_id"], name: "index_model_versions_on_model_id"
  end

  create_table "model_versions_projects", id: false,  force: :cascade do |t|
    t.integer "project_id"
    t.integer "version_id"
  end

  create_table "models", id: :integer,  force: :cascade do |t|
    t.integer "contributor_id"
    t.string "title"
    t.text "description"
    t.integer "recommended_environment_id"
    t.datetime "last_used_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "organism_id"
    t.integer "model_type_id"
    t.integer "model_format_id"
    t.integer "version", default: 1
    t.string "first_letter", limit: 1
    t.text "other_creators"
    t.string "uuid"
    t.integer "policy_id"
    t.string "imported_source"
    t.string "imported_url"
    t.integer "model_image_id"
    t.string "doi"
    t.string "license"
    t.string "deleted_contributor"
    t.integer "human_disease_id"
    t.index ["contributor_id"], name: "index_models_on_contributor"
  end

  create_table "models_projects", id: false,  force: :cascade do |t|
    t.integer "project_id"
    t.integer "model_id"
    t.index ["model_id", "project_id"], name: "index_models_projects_on_model_id_and_project_id"
    t.index ["project_id"], name: "index_models_projects_on_project_id"
  end

  create_table "moderatorships", id: :integer,  force: :cascade do |t|
    t.integer "forum_id"
    t.integer "user_id"
    t.index ["forum_id"], name: "index_moderatorships_on_forum_id"
  end

  create_table "modifications", id: :integer,  force: :cascade do |t|
    t.string "title"
    t.string "symbol"
    t.text "description"
    t.string "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "node_auth_lookup",  force: :cascade do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view", default: false
    t.boolean "can_manage", default: false
    t.boolean "can_edit", default: false
    t.boolean "can_download", default: false
    t.boolean "can_delete", default: false
    t.index ["user_id", "asset_id", "can_view"], name: "index_n_auth_lookup_on_user_id_and_asset_id_and_can_view"
    t.index ["user_id", "can_view"], name: "index_n_auth_lookup_on_user_id_and_can_view"
  end

  create_table "node_versions", id: :integer,  force: :cascade do |t|
    t.integer "node_id"
    t.integer "version"
    t.text "revision_comments"
    t.integer "contributor_id"
    t.string "title"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_used_at"
    t.string "first_letter", limit: 1
    t.text "other_creators"
    t.string "uuid"
    t.integer "policy_id"
    t.string "doi"
    t.string "license"
    t.string "deleted_contributor"
    t.integer "visibility"
    t.index ["contributor_id"], name: "index_node_versions_on_contributor"
    t.index ["node_id"], name: "index_node_versions_on_node_id"
  end

  create_table "node_versions_projects", id: false,  force: :cascade do |t|
    t.integer "project_id"
    t.integer "version_id"
  end

  create_table "nodes", id: :integer,  force: :cascade do |t|
    t.integer "contributor_id"
    t.string "title"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_used_at"
    t.integer "version", default: 1
    t.string "first_letter", limit: 1
    t.text "other_creators"
    t.string "uuid"
    t.integer "policy_id"
    t.string "doi"
    t.string "license"
    t.string "deleted_contributor"
    t.index ["contributor_id"], name: "index_nodes_on_contributor"
  end

  create_table "nodes_projects", id: false,  force: :cascade do |t|
    t.integer "project_id"
    t.integer "node_id"
  end

  create_table "notifiee_infos", id: :integer,  force: :cascade do |t|
    t.integer "notifiee_id"
    t.string "notifiee_type"
    t.string "unique_key"
    t.boolean "receive_notifications", default: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "number_value_versions", id: :integer,  force: :cascade do |t|
    t.integer "number_value_id", null: false
    t.integer "version", null: false
    t.integer "version_creator_id"
    t.integer "number", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["number_value_id"], name: "index_number_value_versions_on_number_value_id"
  end

  create_table "number_values", id: :integer,  force: :cascade do |t|
    t.integer "version"
    t.integer "version_creator_id"
    t.integer "number", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "oauth_access_grants",  force: :cascade do |t|
    t.bigint "resource_owner_id", null: false
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "scopes", default: "", null: false
    t.string "code_challenge"
    t.string "code_challenge_method"
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens",  force: :cascade do |t|
    t.bigint "resource_owner_id"
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.string "scopes"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications",  force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "owner_id"
    t.string "owner_type"
    t.index ["owner_id", "owner_type"], name: "index_oauth_applications_on_owner_id_and_owner_type"
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "oauth_sessions", id: :integer,  force: :cascade do |t|
    t.integer "user_id"
    t.string "provider"
    t.string "access_token"
    t.string "refresh_token"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_oauth_sessions_on_user_id"
  end

  create_table "openbis_endpoints", id: :integer,  force: :cascade do |t|
    t.string "as_endpoint"
    t.string "space_perm_id"
    t.string "username"
    t.integer "project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "dss_endpoint"
    t.string "web_endpoint"
    t.integer "refresh_period_mins", default: 120
    t.integer "policy_id"
    t.string "encrypted_password"
    t.string "encrypted_password_iv"
    t.text "meta_config_json"
    t.datetime "last_sync"
    t.datetime "last_cache_refresh"
  end

  create_table "organisms", id: :integer,  force: :cascade do |t|
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "first_letter"
    t.string "uuid"
  end

  create_table "organisms_projects", id: false,  force: :cascade do |t|
    t.integer "organism_id"
    t.integer "project_id"
    t.index ["organism_id", "project_id"], name: "index_organisms_projects_on_organism_id_and_project_id"
    t.index ["project_id"], name: "index_organisms_projects_on_project_id"
  end

  create_table "people", id: :integer,  force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "phone"
    t.string "skype_name"
    t.text "web_page"
    t.text "description"
    t.integer "avatar_id"
    t.integer "status_id", default: 0
    t.string "first_letter", limit: 10
    t.string "uuid"
    t.integer "roles_mask", default: 0
    t.string "orcid"
  end

  create_table "permissions", id: :integer,  force: :cascade do |t|
    t.string "contributor_type"
    t.integer "contributor_id"
    t.integer "policy_id"
    t.integer "access_type", limit: 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["policy_id"], name: "index_permissions_on_policy_id"
  end

  create_table "phenotypes", id: :integer,  force: :cascade do |t|
    t.text "description"
    t.text "comment"
    t.integer "strain_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "policies", id: :integer,  force: :cascade do |t|
    t.string "name"
    t.integer "sharing_scope", limit: 1
    t.integer "access_type", limit: 1
    t.boolean "use_whitelist"
    t.boolean "use_blacklist"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "presentation_auth_lookup",  force: :cascade do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view", default: false
    t.boolean "can_manage", default: false
    t.boolean "can_edit", default: false
    t.boolean "can_download", default: false
    t.boolean "can_delete", default: false
    t.index ["user_id", "asset_id", "can_view"], name: "index_presentation_user_id_asset_id_can_view"
    t.index ["user_id", "can_view"], name: "index_presentation_auth_lookup_on_user_id_and_can_view"
  end

  create_table "presentation_versions", id: :integer,  force: :cascade do |t|
    t.integer "presentation_id"
    t.integer "version"
    t.text "revision_comments"
    t.integer "contributor_id"
    t.string "title"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_used_at"
    t.string "first_letter", limit: 1
    t.text "other_creators"
    t.string "uuid"
    t.integer "policy_id"
    t.string "license"
    t.string "deleted_contributor"
    t.integer "visibility"
  end

  create_table "presentation_versions_projects", id: false,  force: :cascade do |t|
    t.integer "project_id"
    t.integer "version_id"
  end

  create_table "presentations", id: :integer,  force: :cascade do |t|
    t.integer "contributor_id"
    t.string "title"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_used_at"
    t.integer "version", default: 1
    t.string "first_letter", limit: 1
    t.text "other_creators"
    t.string "uuid"
    t.integer "policy_id"
    t.string "license"
    t.string "deleted_contributor"
  end

  create_table "presentations_projects", id: false,  force: :cascade do |t|
    t.integer "project_id"
    t.integer "presentation_id"
    t.index ["presentation_id", "project_id"], name: "index_presentations_projects_pres_proj_id"
    t.index ["project_id"], name: "index_presentations_projects_on_project_id"
  end

  create_table "presentations_workflows", id: false,  force: :cascade do |t|
    t.bigint "workflow_id", null: false
    t.bigint "presentation_id", null: false
    t.index ["presentation_id", "workflow_id"], name: "index_presentations_workflows_on_pres_workflow"
    t.index ["workflow_id", "presentation_id"], name: "index_presentations_workflows_on_workflow_pres"
  end

  create_table "programmes", id: :integer,  force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.integer "avatar_id"
    t.text "web_page"
    t.string "first_letter", limit: 1
    t.string "uuid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "funding_details"
    t.boolean "is_activated", default: false
    t.text "activation_rejection_reason"
    t.boolean "open_for_projects", default: false
  end

  create_table "project_descendants", id: false,  force: :cascade do |t|
    t.integer "ancestor_id"
    t.integer "descendant_id"
  end

  create_table "project_folder_assets", id: :integer,  force: :cascade do |t|
    t.integer "asset_id"
    t.string "asset_type"
    t.integer "project_folder_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "project_folders", id: :integer,  force: :cascade do |t|
    t.integer "project_id"
    t.string "title"
    t.text "description"
    t.integer "parent_id"
    t.boolean "editable", default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "incoming", default: false
    t.boolean "deletable", default: true
  end

  create_table "project_positions", id: :integer,  force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "project_subscriptions", id: :integer,  force: :cascade do |t|
    t.integer "person_id"
    t.integer "project_id"
    t.string "unsubscribed_types"
    t.string "frequency"
    t.index ["person_id", "project_id"], name: "index_project_subscriptions_on_person_id_and_project_id"
  end

  create_table "projects", id: :integer,  force: :cascade do |t|
    t.string "title"
    t.text "web_page"
    t.text "wiki_page"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "description"
    t.integer "avatar_id"
    t.integer "default_policy_id"
    t.string "first_letter", limit: 1
    t.string "site_credentials"
    t.string "site_root_uri"
    t.datetime "last_jerm_run"
    t.string "uuid"
    t.integer "programme_id"
    t.integer "ancestor_id"
    t.integer "parent_id"
    t.string "default_license", default: "CC-BY-4.0"
    t.boolean "use_default_policy", default: false
    t.date "start_date"
    t.date "end_date"
  end

  create_table "projects_publication_versions", id: false,  force: :cascade do |t|
    t.integer "project_id"
    t.integer "version_id"
  end

  create_table "projects_publications", id: false,  force: :cascade do |t|
    t.integer "project_id"
    t.integer "publication_id"
    t.index ["project_id"], name: "index_projects_publications_on_project_id"
    t.index ["publication_id", "project_id"], name: "index_projects_publications_on_publication_id_and_project_id"
  end

  create_table "projects_sample_types", id: false,  force: :cascade do |t|
    t.integer "project_id"
    t.integer "sample_type_id"
    t.index ["project_id"], name: "index_projects_sample_types_on_project_id"
    t.index ["sample_type_id", "project_id"], name: "index_projects_sample_types_on_sample_type_id_and_project_id"
  end

  create_table "projects_samples", id: false,  force: :cascade do |t|
    t.integer "project_id"
    t.integer "sample_id"
  end

  create_table "projects_sop_versions", id: false,  force: :cascade do |t|
    t.integer "project_id"
    t.integer "version_id"
  end

  create_table "projects_sops", id: false,  force: :cascade do |t|
    t.integer "project_id"
    t.integer "sop_id"
  end

  create_table "projects_strains", id: false,  force: :cascade do |t|
    t.integer "project_id"
    t.integer "strain_id"
  end

  create_table "projects_templates",  force: :cascade do |t|
    t.bigint "template_id"
    t.bigint "project_id"
    t.index ["project_id"], name: "index_projects_templates_on_project_id"
    t.index ["template_id"], name: "index_projects_templates_on_template_id"
  end

  create_table "projects_workflow_versions", id: false,  force: :cascade do |t|
    t.integer "project_id"
    t.integer "version_id"
  end

  create_table "projects_workflows", id: false,  force: :cascade do |t|
    t.integer "project_id"
    t.integer "workflow_id"
  end

  create_table "publication_auth_lookup",  force: :cascade do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view", default: false
    t.boolean "can_manage", default: false
    t.boolean "can_edit", default: false
    t.boolean "can_download", default: false
    t.boolean "can_delete", default: false
    t.index ["user_id", "asset_id", "can_view"], name: "index_pub_user_id_asset_id_can_view"
    t.index ["user_id", "can_view"], name: "index_publication_auth_lookup_on_user_id_and_can_view"
  end

  create_table "publication_authors", id: :integer,  force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.integer "publication_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "author_index"
    t.integer "person_id"
  end

  create_table "publication_types", id: :integer,  force: :cascade do |t|
    t.string "title"
    t.string "key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "publication_versions",  force: :cascade do |t|
    t.integer "publication_id"
    t.integer "version"
    t.text "revision_comments"
    t.integer "pubmed_id"
    t.text "title"
    t.text "abstract"
    t.date "published_date"
    t.string "journal"
    t.string "first_letter", limit: 1
    t.integer "contributor_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_used_at"
    t.string "doi"
    t.string "uuid"
    t.integer "policy_id"
    t.text "citation"
    t.string "deleted_contributor"
    t.integer "registered_mode"
    t.text "booktitle"
    t.string "publisher"
    t.text "editor"
    t.integer "publication_type_id"
    t.text "url"
    t.integer "visibility"
    t.index ["contributor_id"], name: "index_publication_versions_on_contributor"
    t.index ["publication_id"], name: "index_publication_versions_on_publication_id"
  end

  create_table "publications", id: :integer,  force: :cascade do |t|
    t.integer "pubmed_id"
    t.text "title"
    t.text "abstract"
    t.date "published_date"
    t.string "journal"
    t.string "first_letter", limit: 1
    t.integer "contributor_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_used_at"
    t.string "doi"
    t.string "uuid"
    t.integer "policy_id"
    t.text "citation"
    t.string "deleted_contributor"
    t.integer "registered_mode"
    t.text "booktitle"
    t.string "publisher"
    t.text "editor"
    t.integer "publication_type_id"
    t.text "url"
    t.integer "version", default: 1
    t.string "license"
    t.text "other_creators"
    t.index ["contributor_id"], name: "index_publications_on_contributor"
  end

  create_table "rdf_generation_queues",  force: :cascade do |t|
    t.integer "item_id"
    t.string "item_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "priority", default: 0
    t.boolean "refresh_dependents"
    t.index ["item_id", "item_type"], name: "index_rdf_generation_queues_on_item_id_and_item_type"
  end

  create_table "recommended_model_environments", id: :integer,  force: :cascade do |t|
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reindexing_queues", id: :integer,  force: :cascade do |t|
    t.string "item_type"
    t.integer "item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "priority", default: 0
    t.index ["item_id", "item_type"], name: "index_reindexing_queues_on_item_id_and_item_type"
  end

  create_table "relationship_types", id: :integer,  force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "key"
  end

  create_table "relationships", id: :integer,  force: :cascade do |t|
    t.string "subject_type", null: false
    t.integer "subject_id", null: false
    t.string "predicate", null: false
    t.string "other_object_type", null: false
    t.integer "other_object_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "resource_publish_logs", id: :integer,  force: :cascade do |t|
    t.string "resource_type"
    t.integer "resource_id"
    t.integer "user_id"
    t.integer "publish_state"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "comment"
    t.index ["publish_state"], name: "index_resource_publish_logs_on_publish_state"
    t.index ["resource_type", "resource_id"], name: "index_resource_publish_logs_on_resource_type_and_resource_id"
    t.index ["user_id"], name: "index_resource_publish_logs_on_user_id"
  end

  create_table "sample_attribute_types", id: :integer,  force: :cascade do |t|
    t.string "title"
    t.string "base_type"
    t.text "regexp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "placeholder"
    t.text "description"
    t.string "resolution"
  end

  create_table "sample_attributes", id: :integer,  force: :cascade do |t|
    t.string "title"
    t.integer "sample_attribute_type_id"
    t.boolean "required", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "pos"
    t.integer "sample_type_id"
    t.integer "unit_id"
    t.boolean "is_title", default: false
    t.integer "template_column_index"
    t.string "original_accessor_name"
    t.integer "sample_controlled_vocab_id"
    t.integer "linked_sample_type_id"
    t.string "pid"
    t.text "description"
    t.index ["sample_type_id"], name: "index_sample_attributes_on_sample_type_id"
    t.index ["unit_id"], name: "index_sample_attributes_on_unit_id"
  end

  create_table "sample_auth_lookup",  force: :cascade do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view", default: false
    t.boolean "can_manage", default: false
    t.boolean "can_edit", default: false
    t.boolean "can_download", default: false
    t.boolean "can_delete", default: false
    t.index ["user_id", "asset_id", "can_view"], name: "index_sample_user_id_asset_id_can_view"
    t.index ["user_id", "can_view"], name: "index_sample_auth_lookup_on_user_id_and_can_view"
  end

  create_table "sample_controlled_vocab_terms", id: :integer,  force: :cascade do |t|
    t.text "label"
    t.integer "sample_controlled_vocab_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "iri"
    t.string "parent_iri"
  end

  create_table "sample_controlled_vocabs", id: :integer,  force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_letter", limit: 1
    t.string "source_ontology"
    t.string "ols_root_term_uri"
    t.boolean "required"
    t.string "short_name"
    t.integer "template_id"
    t.string "key"
  end

  create_table "sample_resource_links", id: :integer,  force: :cascade do |t|
    t.integer "sample_id"
    t.integer "resource_id"
    t.string "resource_type"
    t.index ["resource_id", "resource_type"], name: "index_sample_resource_links_on_resource_id_and_resource_type"
    t.index ["sample_id"], name: "index_sample_resource_links_on_sample_id"
  end

  create_table "sample_types", id: :integer,  force: :cascade do |t|
    t.string "title"
    t.string "uuid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_letter", limit: 1
    t.text "description"
    t.boolean "uploaded_template", default: false
    t.integer "contributor_id"
    t.string "deleted_contributor"
    t.integer "template_id"
  end

  create_table "samples", id: :integer,  force: :cascade do |t|
    t.string "title"
    t.integer "sample_type_id"
    t.text "json_metadata"
    t.string "uuid"
    t.integer "contributor_id"
    t.integer "policy_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_letter", limit: 1
    t.text "other_creators"
    t.integer "originating_data_file_id"
    t.string "deleted_contributor"
  end

  create_table "saved_searches", id: :integer,  force: :cascade do |t|
    t.integer "user_id"
    t.text "search_query"
    t.text "search_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "include_external_search", default: false
  end

  create_table "scales", id: :integer,  force: :cascade do |t|
    t.string "title"
    t.string "key"
    t.integer "pos", default: 1
    t.string "image_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "scalings", id: :integer,  force: :cascade do |t|
    t.integer "scale_id"
    t.integer "scalable_id"
    t.integer "person_id"
    t.string "scalable_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", id: :integer,  force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data", limit: 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["session_id"], name: "index_sessions_on_session_id"
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "settings", id: :integer,  force: :cascade do |t|
    t.string "var", null: false
    t.text "value"
    t.integer "target_id"
    t.string "target_type", limit: 30
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "encrypted_value"
    t.string "encrypted_value_iv"
    t.index ["target_type", "target_id", "var"], name: "index_settings_on_target_type_and_target_id_and_var", unique: true
  end

  create_table "site_announcement_categories", id: :integer,  force: :cascade do |t|
    t.string "title"
    t.string "icon_key"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "site_announcements", id: :integer,  force: :cascade do |t|
    t.integer "announcer_id"
    t.string "announcer_type"
    t.string "title"
    t.text "body"
    t.integer "site_announcement_category_id"
    t.boolean "is_headline", default: false
    t.datetime "expires_at"
    t.boolean "show_in_feed", default: true
    t.boolean "email_notification", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "snapshots", id: :integer,  force: :cascade do |t|
    t.string "resource_type"
    t.integer "resource_id"
    t.string "doi"
    t.integer "snapshot_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "zenodo_deposition_id"
    t.string "zenodo_record_url"
  end

  create_table "sop_auth_lookup",  force: :cascade do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view", default: false
    t.boolean "can_manage", default: false
    t.boolean "can_edit", default: false
    t.boolean "can_download", default: false
    t.boolean "can_delete", default: false
    t.index ["user_id", "asset_id", "can_view"], name: "index_sop_auth_lookup_on_user_id_and_asset_id_and_can_view"
    t.index ["user_id", "can_view"], name: "index_sop_auth_lookup_on_user_id_and_can_view"
  end

  create_table "sop_versions", id: :integer,  force: :cascade do |t|
    t.integer "sop_id"
    t.integer "version"
    t.text "revision_comments"
    t.integer "contributor_id"
    t.string "title"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_used_at"
    t.string "first_letter", limit: 1
    t.text "other_creators"
    t.string "uuid"
    t.integer "policy_id"
    t.string "doi"
    t.string "license"
    t.string "deleted_contributor"
    t.integer "visibility"
    t.index ["contributor_id"], name: "index_sop_versions_on_contributor"
    t.index ["sop_id"], name: "index_sop_versions_on_sop_id"
  end

  create_table "sops", id: :integer,  force: :cascade do |t|
    t.integer "contributor_id"
    t.string "title"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_used_at"
    t.integer "version", default: 1
    t.string "first_letter", limit: 1
    t.text "other_creators"
    t.string "uuid"
    t.integer "policy_id"
    t.string "doi"
    t.string "license"
    t.string "deleted_contributor"
    t.index ["contributor_id"], name: "index_sops_on_contributor"
  end

  create_table "sops_workflows", id: false,  force: :cascade do |t|
    t.integer "workflow_id", null: false
    t.integer "sop_id", null: false
    t.index ["sop_id"], name: "index_sops_workflows_on_sop_id"
    t.index ["workflow_id"], name: "index_sops_workflows_on_workflow_id"
  end

  create_table "special_auth_codes", id: :integer,  force: :cascade do |t|
    t.string "code"
    t.date "expiration_date"
    t.string "asset_type"
    t.integer "asset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "strain_auth_lookup",  force: :cascade do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view", default: false
    t.boolean "can_manage", default: false
    t.boolean "can_edit", default: false
    t.boolean "can_download", default: false
    t.boolean "can_delete", default: false
    t.index ["user_id", "asset_id", "can_view"], name: "index_strain_user_id_asset_id_can_view"
    t.index ["user_id", "can_view"], name: "index_strain_auth_lookup_on_user_id_and_can_view"
  end

  create_table "strain_descendants", id: false,  force: :cascade do |t|
    t.integer "ancestor_id"
    t.integer "descendant_id"
  end

  create_table "strains", id: :integer,  force: :cascade do |t|
    t.string "title"
    t.integer "organism_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "parent_id"
    t.string "synonym"
    t.text "comment"
    t.string "provider_id"
    t.string "provider_name"
    t.boolean "is_dummy", default: false
    t.integer "contributor_id"
    t.integer "policy_id"
    t.string "uuid"
    t.string "first_letter"
    t.string "deleted_contributor"
  end

  create_table "studied_factor_links", id: :integer,  force: :cascade do |t|
    t.string "substance_type"
    t.integer "substance_id"
    t.integer "studied_factor_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "studied_factors", id: :integer,  force: :cascade do |t|
    t.integer "measured_item_id"
    t.float "start_value"
    t.float "end_value"
    t.integer "unit_id"
    t.float "time_point"
    t.integer "data_file_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float "standard_deviation"
    t.integer "data_file_version"
    t.index ["data_file_id"], name: "index_studied_factors_on_data_file_id"
  end

  create_table "studies", id: :integer,  force: :cascade do |t|
    t.text "title"
    t.text "description"
    t.integer "investigation_id"
    t.text "experimentalists"
    t.datetime "begin_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "first_letter", limit: 1
    t.string "uuid"
    t.integer "policy_id"
    t.integer "contributor_id"
    t.text "other_creators"
    t.string "deleted_contributor"
    t.integer "position"
  end

  create_table "study_auth_lookup",  force: :cascade do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view", default: false
    t.boolean "can_manage", default: false
    t.boolean "can_edit", default: false
    t.boolean "can_download", default: false
    t.boolean "can_delete", default: false
    t.index ["user_id", "asset_id", "can_view"], name: "index_study_auth_lookup_on_user_id_and_asset_id_and_can_view"
    t.index ["user_id", "can_view"], name: "index_study_auth_lookup_on_user_id_and_can_view"
  end

  create_table "subscriptions", id: :integer,  force: :cascade do |t|
    t.integer "person_id"
    t.integer "subscribable_id"
    t.string "subscribable_type"
    t.string "subscription_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "project_subscription_id"
  end

  create_table "suggested_assay_types", id: :integer,  force: :cascade do |t|
    t.string "label"
    t.string "ontology_uri"
    t.integer "contributor_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "parent_id"
  end

  create_table "suggested_technology_types", id: :integer,  force: :cascade do |t|
    t.string "label"
    t.string "ontology_uri"
    t.integer "contributor_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "parent_id"
  end

  create_table "synonyms", id: :integer,  force: :cascade do |t|
    t.string "name"
    t.integer "substance_id"
    t.string "substance_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["substance_id", "substance_type"], name: "index_synonyms_on_substance_id_and_substance_type"
  end

  create_table "taggings", id: :integer,  force: :cascade do |t|
    t.integer "tag_id"
    t.integer "taggable_id"
    t.integer "tagger_id"
    t.string "tagger_type"
    t.string "taggable_type"
    t.string "context"
    t.datetime "created_at"
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context"
  end

  create_table "tags", id: :integer,  force: :cascade do |t|
    t.string "name"
  end

  create_table "tasks",  force: :cascade do |t|
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "key"
    t.string "status"
    t.integer "attempts", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["resource_type", "resource_id"], name: "index_tasks_on_resource_type_and_resource_id"
  end

  create_table "template_attributes",  force: :cascade do |t|
    t.string "title"
    t.string "short_name"
    t.boolean "required", default: false
    t.string "ontology_version"
    t.text "description"
    t.integer "template_id"
    t.integer "sample_controlled_vocab_id"
    t.integer "sample_attribute_type_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "unit_id"
    t.integer "pos"
    t.boolean "is_title", default: false
    t.integer "isa_tag_id"
    t.string "iri"
    t.index ["template_id", "title"], name: "index_template_id_asset_id_title"
  end

  create_table "template_auth_lookup", id: :integer,  force: :cascade do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view", default: false
    t.boolean "can_manage", default: false
    t.boolean "can_edit", default: false
    t.boolean "can_download", default: false
    t.boolean "can_delete", default: false
    t.index ["user_id", "asset_id", "can_view"], name: "index_template_auth_lookup_user_id_asset_id"
    t.index ["user_id", "can_view"], name: "index_template_auth_lookup_on_user_id_and_can_view"
  end

  create_table "templates",  force: :cascade do |t|
    t.string "title"
    t.string "group", default: "other"
    t.integer "group_order"
    t.string "temporary_name"
    t.string "template_version"
    t.string "isa_config"
    t.string "isa_measurement_type"
    t.string "isa_technology_type"
    t.string "isa_protocol_type"
    t.string "repo_schema_id"
    t.string "organism", default: "other"
    t.string "level", default: "other"
    t.text "description"
    t.integer "policy_id"
    t.integer "contributor_id"
    t.string "deleted_contributor"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "parent_id"
    t.index ["title", "group"], name: "index_templates_title_group"
  end

  create_table "text_values", id: :integer,  force: :cascade do |t|
    t.integer "version"
    t.integer "version_creator_id"
    t.text "text", limit: 16777215, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tissue_and_cell_types", id: :integer,  force: :cascade do |t|
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "units", id: :integer,  force: :cascade do |t|
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "symbol"
    t.string "comment"
    t.boolean "factors_studied", default: true
    t.integer "order"
  end

  create_table "users", id: :integer,  force: :cascade do |t|
    t.string "login"
    t.string "crypted_password", limit: 64
    t.string "salt", limit: 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "remember_token"
    t.datetime "remember_token_expires_at"
    t.string "activation_code", limit: 40
    t.datetime "activated_at"
    t.integer "person_id"
    t.string "reset_password_code"
    t.datetime "reset_password_code_until"
    t.integer "posts_count", default: 0
    t.datetime "last_seen_at"
    t.string "uuid"
  end

  create_table "work_groups", id: :integer,  force: :cascade do |t|
    t.string "name"
    t.integer "institution_id"
    t.integer "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["project_id"], name: "index_work_groups_on_project_id"
  end

  create_table "workflow_auth_lookup",  force: :cascade do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view", default: false
    t.boolean "can_manage", default: false
    t.boolean "can_edit", default: false
    t.boolean "can_download", default: false
    t.boolean "can_delete", default: false
    t.index ["user_id", "asset_id", "can_view"], name: "index_w_auth_lookup_on_user_id_and_asset_id_and_can_view"
    t.index ["user_id", "can_view"], name: "index_w_auth_lookup_on_user_id_and_can_view"
  end

  create_table "workflow_classes",  force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.string "key"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "extractor"
    t.bigint "contributor_id"
    t.string "alternate_name"
    t.text "identifier"
    t.text "url"
    t.index ["contributor_id"], name: "index_workflow_classes_on_contributor_id"
  end

  create_table "workflow_data_file_relationships",  force: :cascade do |t|
    t.string "title"
    t.string "key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "workflow_data_files",  force: :cascade do |t|
    t.integer "workflow_id"
    t.integer "data_file_id"
    t.integer "workflow_data_file_relationship_id"
    t.index ["data_file_id", "workflow_id"], name: "index_data_files_workflows_on_data_file_workflow"
    t.index ["workflow_id", "data_file_id"], name: "index_data_files_workflows_on_workflow_data_file"
  end

  create_table "workflow_versions", id: :integer,  force: :cascade do |t|
    t.integer "workflow_id"
    t.integer "version"
    t.text "revision_comments"
    t.integer "contributor_id"
    t.string "title"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_used_at"
    t.string "first_letter", limit: 1
    t.text "other_creators"
    t.string "uuid"
    t.integer "policy_id"
    t.string "doi"
    t.string "license"
    t.string "deleted_contributor"
    t.text "metadata"
    t.integer "workflow_class_id"
    t.integer "maturity_level"
    t.integer "visibility"
    t.boolean "monitored"
    t.integer "test_status"
    t.index ["contributor_id"], name: "index_workflow_versions_on_contributor"
    t.index ["workflow_id"], name: "index_workflow_versions_on_workflow_id"
  end

  create_table "workflows", id: :integer,  force: :cascade do |t|
    t.integer "contributor_id"
    t.string "title"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_used_at"
    t.integer "version", default: 1
    t.string "first_letter", limit: 1
    t.text "other_creators"
    t.string "uuid"
    t.integer "policy_id"
    t.string "doi"
    t.string "license"
    t.string "deleted_contributor"
    t.text "metadata"
    t.integer "workflow_class_id"
    t.integer "maturity_level"
    t.integer "test_status"
    t.index ["contributor_id"], name: "index_workflows_on_contributor"
  end

  create_table "worksheets", id: :integer,  force: :cascade do |t|
    t.integer "content_blob_id"
    t.integer "last_row"
    t.integer "last_column"
    t.integer "sheet_number"
  end

  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
end
