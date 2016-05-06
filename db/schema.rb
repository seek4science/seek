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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20160505094646) do

  create_table "activity_logs", :force => true do |t|
    t.string   "action"
    t.string   "format"
    t.string   "activity_loggable_type"
    t.integer  "activity_loggable_id"
    t.string   "culprit_type"
    t.integer  "culprit_id"
    t.string   "referenced_type"
    t.integer  "referenced_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "http_referer"
    t.string   "user_agent"
    t.text     "data",                   :limit => 16777215
    t.string   "controller_name"
  end

  add_index "activity_logs", ["action"], :name => "act_logs_action_index"
  add_index "activity_logs", ["activity_loggable_type", "activity_loggable_id"], :name => "act_logs_act_loggable_index"
  add_index "activity_logs", ["culprit_type", "culprit_id"], :name => "act_logs_culprit_index"
  add_index "activity_logs", ["format"], :name => "act_logs_format_index"
  add_index "activity_logs", ["referenced_type", "referenced_id"], :name => "act_logs_referenced_index"

  create_table "admin_defined_role_programmes", :force => true do |t|
    t.integer "programme_id"
    t.integer "person_id"
    t.integer "role_mask"
  end

  create_table "admin_defined_role_projects", :force => true do |t|
    t.integer "project_id"
    t.integer "role_mask"
    t.integer "person_id"
  end

  create_table "annotation_attributes", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "identifier", :null => false
  end

  add_index "annotation_attributes", ["name"], :name => "index_annotation_attributes_on_name"

  create_table "annotation_value_seeds", :force => true do |t|
    t.integer  "attribute_id",                                    :null => false
    t.string   "old_value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "value_type",   :limit => 50, :default => "FIXME", :null => false
    t.integer  "value_id",                   :default => 0,       :null => false
  end

  add_index "annotation_value_seeds", ["attribute_id"], :name => "index_annotation_value_seeds_on_attribute_id"

  create_table "annotation_versions", :force => true do |t|
    t.integer  "annotation_id",                                         :null => false
    t.integer  "version",                                               :null => false
    t.integer  "version_creator_id"
    t.string   "source_type",                                           :null => false
    t.integer  "source_id",                                             :null => false
    t.string   "annotatable_type",   :limit => 50,                      :null => false
    t.integer  "annotatable_id",                                        :null => false
    t.integer  "attribute_id",                                          :null => false
    t.string   "old_value",                        :default => ""
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "value_type",         :limit => 50, :default => "FIXME", :null => false
    t.integer  "value_id",                         :default => 0,       :null => false
  end

  add_index "annotation_versions", ["annotation_id"], :name => "index_annotation_versions_on_annotation_id"

  create_table "annotations", :force => true do |t|
    t.string   "source_type",                                           :null => false
    t.integer  "source_id",                                             :null => false
    t.string   "annotatable_type",   :limit => 50,                      :null => false
    t.integer  "annotatable_id",                                        :null => false
    t.integer  "attribute_id",                                          :null => false
    t.string   "old_value",                        :default => ""
    t.integer  "version"
    t.integer  "version_creator_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "value_type",         :limit => 50, :default => "FIXME", :null => false
    t.integer  "value_id",                         :default => 0,       :null => false
  end

  add_index "annotations", ["annotatable_type", "annotatable_id"], :name => "index_annotations_on_annotatable_type_and_annotatable_id"
  add_index "annotations", ["attribute_id"], :name => "index_annotations_on_attribute_id"
  add_index "annotations", ["source_type", "source_id"], :name => "index_annotations_on_source_type_and_source_id"
  add_index "annotations", ["value_type", "value_id"], :name => "index_annotations_on_value_type_and_value_id"

  create_table "assay_assets", :force => true do |t|
    t.integer  "assay_id"
    t.integer  "asset_id"
    t.integer  "version"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "relationship_type_id"
    t.string   "asset_type"
    t.integer  "direction",            :default => 0
  end

  add_index "assay_assets", ["assay_id"], :name => "index_assay_assets_on_assay_id"
  add_index "assay_assets", ["asset_id", "asset_type"], :name => "index_assay_assets_on_asset_id_and_asset_type"

  create_table "assay_auth_lookup", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view",     :default => false
    t.boolean "can_manage",   :default => false
    t.boolean "can_edit",     :default => false
    t.boolean "can_download", :default => false
    t.boolean "can_delete",   :default => false
  end

  add_index "assay_auth_lookup", ["user_id", "asset_id", "can_view"], :name => "index_assay_auth_lookup_on_user_id_and_asset_id_and_can_view"
  add_index "assay_auth_lookup", ["user_id", "can_view"], :name => "index_assay_auth_lookup_on_user_id_and_can_view"

  create_table "assay_classes", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "key",         :limit => 10
  end

  create_table "assay_organisms", :force => true do |t|
    t.integer  "assay_id"
    t.integer  "organism_id"
    t.integer  "culture_growth_type_id"
    t.integer  "strain_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "tissue_and_cell_type_id"
  end

  add_index "assay_organisms", ["assay_id"], :name => "index_assay_organisms_on_assay_id"
  add_index "assay_organisms", ["organism_id"], :name => "index_assay_organisms_on_organism_id"

  create_table "assays", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "study_id"
    t.integer  "owner_id"
    t.string   "first_letter",                 :limit => 1
    t.integer  "assay_class_id"
    t.string   "uuid"
    t.integer  "policy_id"
    t.integer  "institution_id"
    t.string   "assay_type_uri"
    t.string   "technology_type_uri"
    t.integer  "suggested_assay_type_id"
    t.integer  "suggested_technology_type_id"
    t.text     "other_creators"
  end

  create_table "assays_deprecated_samples", :id => false, :force => true do |t|
    t.integer "assay_id"
    t.integer "deprecated_sample_id"
  end

  create_table "asset_doi_logs", :force => true do |t|
    t.string   "asset_type"
    t.integer  "asset_id"
    t.integer  "asset_version"
    t.integer  "action"
    t.text     "comment"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.integer  "user_id"
    t.string   "doi"
  end

  create_table "assets", :force => true do |t|
    t.integer  "project_id"
    t.string   "resource_type"
    t.integer  "resource_id"
    t.integer  "policy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_used_at"
  end

  create_table "assets_creators", :force => true do |t|
    t.integer  "asset_id"
    t.integer  "creator_id"
    t.string   "asset_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "assets_creators", ["asset_id", "asset_type"], :name => "index_assets_creators_on_asset_id_and_asset_type"

  create_table "auth_lookup_update_queues", :force => true do |t|
    t.integer  "item_id"
    t.string   "item_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "priority",   :default => 0
  end

  create_table "avatars", :force => true do |t|
    t.string   "owner_type"
    t.integer  "owner_id"
    t.string   "original_filename"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "avatars", ["owner_type", "owner_id"], :name => "index_avatars_on_owner_type_and_owner_id"

  create_table "bioportal_concepts", :force => true do |t|
    t.string  "ontology_id"
    t.string  "concept_uri"
    t.text    "cached_concept_yaml"
    t.integer "conceptable_id"
    t.string  "conceptable_type"
  end

  create_table "cell_ranges", :force => true do |t|
    t.integer  "cell_range_id"
    t.integer  "worksheet_id"
    t.integer  "start_row"
    t.integer  "start_column"
    t.integer  "end_row"
    t.integer  "end_column"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "compounds", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "content_blobs", :force => true do |t|
    t.string  "md5sum"
    t.string  "url"
    t.string  "uuid"
    t.string  "original_filename"
    t.string  "content_type"
    t.integer "asset_id"
    t.string  "asset_type"
    t.integer "asset_version"
    t.boolean "is_webpage",                     :default => false
    t.boolean "external_link"
    t.string  "sha1sum"
    t.integer "file_size",         :limit => 8
  end

  add_index "content_blobs", ["asset_id", "asset_type"], :name => "index_content_blobs_on_asset_id_and_asset_type"

  create_table "culture_growth_types", :force => true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cultures", :force => true do |t|
    t.integer  "organism_id"
    t.integer  "sop_id"
    t.datetime "date_at_sampling"
    t.datetime "culture_start_date"
    t.integer  "age_at_sampling"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "data_file_auth_lookup", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view"
    t.boolean "can_manage"
    t.boolean "can_edit"
    t.boolean "can_download"
    t.boolean "can_delete",   :default => false
  end

  add_index "data_file_auth_lookup", ["user_id", "asset_id", "can_view"], :name => "index_data_file_auth_lookup_user_asset_view"
  add_index "data_file_auth_lookup", ["user_id", "can_view"], :name => "index_data_file_auth_lookup_on_user_id_and_can_view"

  create_table "data_file_versions", :force => true do |t|
    t.integer  "data_file_id"
    t.integer  "version"
    t.text     "revision_comments"
    t.string   "contributor_type"
    t.integer  "contributor_id"
    t.string   "title"
    t.text     "description"
    t.integer  "template_id"
    t.datetime "last_used_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_letter",      :limit => 1
    t.text     "other_creators"
    t.string   "uuid"
    t.integer  "policy_id"
    t.boolean  "is_with_sample"
    t.string   "template_name",                  :default => "none"
    t.string   "doi"
    t.string   "license"
  end

  add_index "data_file_versions", ["contributor_id", "contributor_type"], :name => "index_data_file_versions_contributor"
  add_index "data_file_versions", ["data_file_id"], :name => "index_data_file_versions_on_data_file_id"

  create_table "data_file_versions_projects", :id => false, :force => true do |t|
    t.integer "project_id"
    t.integer "version_id"
  end

  create_table "data_files", :force => true do |t|
    t.string   "contributor_type"
    t.integer  "contributor_id"
    t.string   "title"
    t.text     "description"
    t.integer  "template_id"
    t.datetime "last_used_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "version",                       :default => 1
    t.string   "first_letter",     :limit => 1
    t.text     "other_creators"
    t.string   "uuid"
    t.integer  "policy_id"
    t.boolean  "is_with_sample"
    t.string   "template_name",                 :default => "none"
    t.string   "doi"
    t.string   "license"
  end

  add_index "data_files", ["contributor_id", "contributor_type"], :name => "index_data_files_on_contributor_id_and_contributor_type"

  create_table "data_files_events", :id => false, :force => true do |t|
    t.integer "data_file_id"
    t.integer "event_id"
  end

  create_table "data_files_projects", :id => false, :force => true do |t|
    t.integer "project_id"
    t.integer "data_file_id"
  end

  add_index "data_files_projects", ["data_file_id", "project_id"], :name => "index_data_files_projects_on_data_file_id_and_project_id"
  add_index "data_files_projects", ["project_id"], :name => "index_data_files_projects_on_project_id"

  create_table "db_files", :force => true do |t|
    t.binary "data"
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "deprecated_sample_assets", :force => true do |t|
    t.integer  "deprecated_sample_id"
    t.integer  "asset_id"
    t.integer  "version"
    t.string   "asset_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "deprecated_sample_auth_lookup", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view",     :default => false
    t.boolean "can_manage",   :default => false
    t.boolean "can_edit",     :default => false
    t.boolean "can_download", :default => false
    t.boolean "can_delete",   :default => false
  end

  create_table "deprecated_samples", :force => true do |t|
    t.string   "title"
    t.integer  "deprecated_specimen_id"
    t.string   "lab_internal_number"
    t.datetime "donation_date"
    t.string   "explantation"
    t.string   "comments"
    t.string   "first_letter"
    t.integer  "policy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "contributor_id"
    t.string   "contributor_type"
    t.integer  "institution_id"
    t.datetime "sampling_date"
    t.string   "organism_part"
    t.string   "provider_id"
    t.string   "provider_name"
    t.string   "age_at_sampling"
    t.string   "uuid"
    t.integer  "age_at_sampling_unit_id"
    t.string   "sample_type"
    t.string   "treatment"
  end

  create_table "deprecated_samples_projects", :id => false, :force => true do |t|
    t.integer "project_id"
    t.integer "deprecated_sample_id"
  end

  create_table "deprecated_samples_tissue_and_cell_types", :id => false, :force => true do |t|
    t.integer "deprecated_sample_id"
    t.integer "tissue_and_cell_type_id"
  end

  create_table "deprecated_specimen_auth_lookup", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view",     :default => false
    t.boolean "can_manage",   :default => false
    t.boolean "can_edit",     :default => false
    t.boolean "can_download", :default => false
    t.boolean "can_delete",   :default => false
  end

  add_index "deprecated_specimen_auth_lookup", ["user_id", "asset_id", "can_view"], :name => "index_spec_user_id_asset_id_can_view"
  add_index "deprecated_specimen_auth_lookup", ["user_id", "can_view"], :name => "index_specimen_auth_lookup_on_user_id_and_can_view"

  create_table "deprecated_specimens", :force => true do |t|
    t.string   "title"
    t.integer  "age"
    t.string   "treatment"
    t.string   "lab_internal_number"
    t.integer  "person_id"
    t.integer  "institution_id"
    t.string   "comments"
    t.string   "first_letter"
    t.integer  "policy_id"
    t.text     "other_creators"
    t.integer  "contributor_id"
    t.string   "contributor_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "culture_growth_type_id"
    t.integer  "strain_id"
    t.string   "medium"
    t.string   "culture_format"
    t.float    "temperature"
    t.float    "ph"
    t.string   "confluency"
    t.string   "passage"
    t.string   "viability"
    t.string   "purity"
    t.integer  "sex"
    t.datetime "born"
    t.string   "ploidy"
    t.string   "provider_id"
    t.string   "provider_name"
    t.boolean  "is_dummy",               :default => false
    t.string   "uuid"
    t.string   "age_unit"
  end

  create_table "deprecated_specimens_projects", :id => false, :force => true do |t|
    t.integer "project_id"
    t.integer "deprecated_specimen_id"
  end

  create_table "deprecated_treatments", :force => true do |t|
    t.integer  "unit_id"
    t.string   "treatment_protocol"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "deprecated_sample_id"
    t.integer  "measured_item_id"
    t.float    "start_value"
    t.float    "end_value"
    t.float    "standard_deviation"
    t.text     "comments"
    t.integer  "compound_id"
    t.integer  "deprecated_specimen_id"
    t.string   "medium_title"
    t.float    "time_after_treatment"
    t.integer  "time_after_treatment_unit_id"
    t.float    "incubation_time"
    t.integer  "incubation_time_unit_id"
  end

  create_table "disciplines", :force => true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "disciplines_people", :id => false, :force => true do |t|
    t.integer "discipline_id"
    t.integer "person_id"
  end

  add_index "disciplines_people", ["person_id"], :name => "index_disciplines_people_on_person_id"

  create_table "event_auth_lookup", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view",     :default => false
    t.boolean "can_manage",   :default => false
    t.boolean "can_edit",     :default => false
    t.boolean "can_download", :default => false
    t.boolean "can_delete",   :default => false
  end

  add_index "event_auth_lookup", ["user_id", "asset_id", "can_view"], :name => "index_event_auth_lookup_on_user_id_and_asset_id_and_can_view"
  add_index "event_auth_lookup", ["user_id", "can_view"], :name => "index_event_auth_lookup_on_user_id_and_can_view"

  create_table "events", :force => true do |t|
    t.datetime "start_date"
    t.datetime "end_date"
    t.text     "address"
    t.string   "city"
    t.string   "country"
    t.string   "url"
    t.text     "description"
    t.string   "title"
    t.integer  "policy_id"
    t.integer  "contributor_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "contributor_type"
    t.string   "first_letter",     :limit => 1
    t.string   "uuid"
  end

  create_table "events_presentations", :id => false, :force => true do |t|
    t.integer "presentation_id"
    t.integer "event_id"
  end

  create_table "events_projects", :id => false, :force => true do |t|
    t.integer "project_id"
    t.integer "event_id"
  end

  add_index "events_projects", ["event_id", "project_id"], :name => "index_events_projects_on_event_id_and_project_id"
  add_index "events_projects", ["project_id"], :name => "index_events_projects_on_project_id"

  create_table "events_publications", :id => false, :force => true do |t|
    t.integer "publication_id"
    t.integer "event_id"
  end

  create_table "experimental_condition_links", :force => true do |t|
    t.string   "substance_type"
    t.integer  "substance_id"
    t.integer  "experimental_condition_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "experimental_conditions", :force => true do |t|
    t.integer  "measured_item_id"
    t.float    "start_value"
    t.float    "end_value"
    t.integer  "unit_id"
    t.integer  "sop_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sop_version"
  end

  add_index "experimental_conditions", ["sop_id"], :name => "index_experimental_conditions_on_sop_id"

  create_table "favourite_group_memberships", :force => true do |t|
    t.integer  "person_id"
    t.integer  "favourite_group_id"
    t.integer  "access_type",        :limit => 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "favourite_groups", :force => true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "favourites", :force => true do |t|
    t.integer  "resource_id"
    t.integer  "user_id"
    t.string   "resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "forum_attachments", :force => true do |t|
    t.integer  "post_id"
    t.string   "title"
    t.string   "content_type"
    t.string   "filename"
    t.integer  "size"
    t.integer  "db_file_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "forums", :force => true do |t|
    t.string  "name"
    t.string  "description"
    t.integer "topics_count",     :default => 0
    t.integer "posts_count",      :default => 0
    t.integer "position"
    t.text    "description_html"
  end

  create_table "genes", :force => true do |t|
    t.string   "title"
    t.string   "symbol"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "genotypes", :force => true do |t|
    t.integer  "gene_id"
    t.integer  "modification_id"
    t.integer  "strain_id"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "deprecated_specimen_id"
  end

  create_table "group_memberships", :force => true do |t|
    t.integer  "person_id"
    t.integer  "work_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "time_left_at"
  end

  add_index "group_memberships", ["person_id"], :name => "index_group_memberships_on_person_id"
  add_index "group_memberships", ["work_group_id", "person_id"], :name => "index_group_memberships_on_work_group_id_and_person_id"
  add_index "group_memberships", ["work_group_id"], :name => "index_group_memberships_on_work_group_id"

  create_table "group_memberships_project_positions", :force => true do |t|
    t.integer "group_membership_id"
    t.integer "project_position_id"
  end

  create_table "help_attachments", :force => true do |t|
    t.integer  "help_document_id"
    t.string   "title"
    t.string   "content_type"
    t.string   "filename"
    t.integer  "size"
    t.integer  "db_file_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "help_documents", :force => true do |t|
    t.string   "identifier"
    t.string   "title"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "help_images", :force => true do |t|
    t.integer  "help_document_id"
    t.string   "content_type"
    t.string   "filename"
    t.integer  "size"
    t.integer  "height"
    t.integer  "width"
    t.integer  "parent_id"
    t.string   "thumbnail"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "institutions", :force => true do |t|
    t.string   "title"
    t.text     "address"
    t.string   "city"
    t.string   "web_page"
    t.string   "country"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "avatar_id"
    t.string   "first_letter", :limit => 1
    t.string   "uuid"
  end

  create_table "investigation_auth_lookup", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view",     :default => false
    t.boolean "can_manage",   :default => false
    t.boolean "can_edit",     :default => false
    t.boolean "can_download", :default => false
    t.boolean "can_delete",   :default => false
  end

  add_index "investigation_auth_lookup", ["user_id", "asset_id", "can_view"], :name => "index_inv_user_id_asset_id_can_view"
  add_index "investigation_auth_lookup", ["user_id", "can_view"], :name => "index_investigation_auth_lookup_on_user_id_and_can_view"

  create_table "investigations", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_letter",     :limit => 1
    t.string   "uuid"
    t.integer  "policy_id"
    t.integer  "contributor_id"
    t.string   "contributor_type"
    t.text     "other_creators"
  end

  create_table "investigations_projects", :id => false, :force => true do |t|
    t.integer "project_id"
    t.integer "investigation_id"
  end

  add_index "investigations_projects", ["investigation_id", "project_id"], :name => "index_investigations_projects_inv_proj_id"
  add_index "investigations_projects", ["project_id"], :name => "index_investigations_projects_on_project_id"

  create_table "mapping_links", :force => true do |t|
    t.string   "substance_type"
    t.integer  "substance_id"
    t.integer  "mapping_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mappings", :force => true do |t|
    t.integer  "sabiork_id"
    t.string   "chebi_id"
    t.string   "kegg_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "measured_items", :force => true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "factors_studied", :default => true
  end

  create_table "model_auth_lookup", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view",     :default => false
    t.boolean "can_manage",   :default => false
    t.boolean "can_edit",     :default => false
    t.boolean "can_download", :default => false
    t.boolean "can_delete",   :default => false
  end

  add_index "model_auth_lookup", ["user_id", "asset_id", "can_view"], :name => "index_model_auth_lookup_on_user_id_and_asset_id_and_can_view"
  add_index "model_auth_lookup", ["user_id", "can_view"], :name => "index_model_auth_lookup_on_user_id_and_can_view"

  create_table "model_formats", :force => true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "model_images", :force => true do |t|
    t.integer  "model_id"
    t.string   "original_filename"
    t.string   "content_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "image_width"
    t.integer  "image_height"
  end

  create_table "model_types", :force => true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "model_versions", :force => true do |t|
    t.integer  "model_id"
    t.integer  "version"
    t.text     "revision_comments"
    t.string   "contributor_type"
    t.integer  "contributor_id"
    t.string   "title"
    t.text     "description"
    t.integer  "recommended_environment_id"
    t.datetime "last_used_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "organism_id"
    t.integer  "model_type_id"
    t.integer  "model_format_id"
    t.string   "first_letter",               :limit => 1
    t.text     "other_creators"
    t.string   "uuid"
    t.integer  "policy_id"
    t.string   "imported_source"
    t.string   "imported_url"
    t.integer  "model_image_id"
    t.string   "doi"
    t.string   "license"
  end

  add_index "model_versions", ["contributor_id", "contributor_type"], :name => "index_model_versions_on_contributor_id_and_contributor_type"
  add_index "model_versions", ["model_id"], :name => "index_model_versions_on_model_id"

  create_table "model_versions_projects", :id => false, :force => true do |t|
    t.integer "project_id"
    t.integer "version_id"
  end

  create_table "models", :force => true do |t|
    t.string   "contributor_type"
    t.integer  "contributor_id"
    t.string   "title"
    t.text     "description"
    t.integer  "recommended_environment_id"
    t.datetime "last_used_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "organism_id"
    t.integer  "model_type_id"
    t.integer  "model_format_id"
    t.integer  "version",                                 :default => 1
    t.string   "first_letter",               :limit => 1
    t.text     "other_creators"
    t.string   "uuid"
    t.integer  "policy_id"
    t.string   "imported_source"
    t.string   "imported_url"
    t.integer  "model_image_id"
    t.string   "doi"
    t.string   "license"
  end

  add_index "models", ["contributor_id", "contributor_type"], :name => "index_models_on_contributor_id_and_contributor_type"

  create_table "models_projects", :id => false, :force => true do |t|
    t.integer "project_id"
    t.integer "model_id"
  end

  add_index "models_projects", ["model_id", "project_id"], :name => "index_models_projects_on_model_id_and_project_id"
  add_index "models_projects", ["project_id"], :name => "index_models_projects_on_project_id"

  create_table "moderatorships", :force => true do |t|
    t.integer "forum_id"
    t.integer "user_id"
  end

  add_index "moderatorships", ["forum_id"], :name => "index_moderatorships_on_forum_id"

  create_table "modifications", :force => true do |t|
    t.string   "title"
    t.string   "symbol"
    t.text     "description"
    t.string   "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "monitorships", :force => true do |t|
    t.integer "topic_id"
    t.integer "user_id"
    t.boolean "active",   :default => true
  end

  create_table "notifiee_infos", :force => true do |t|
    t.integer  "notifiee_id"
    t.string   "notifiee_type"
    t.string   "unique_key"
    t.boolean  "receive_notifications", :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "number_value_versions", :force => true do |t|
    t.integer  "number_value_id",    :null => false
    t.integer  "version",            :null => false
    t.integer  "version_creator_id"
    t.integer  "number",             :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "number_value_versions", ["number_value_id"], :name => "index_number_value_versions_on_number_value_id"

  create_table "number_values", :force => true do |t|
    t.integer  "version"
    t.integer  "version_creator_id"
    t.integer  "number",             :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "oauth_sessions", :force => true do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.string   "access_token"
    t.string   "refresh_token"
    t.datetime "expires_at"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "oauth_sessions", ["user_id"], :name => "index_oauth_sessions_on_user_id"

  create_table "organisms", :force => true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_letter"
  end

  create_table "organisms_projects", :id => false, :force => true do |t|
    t.integer "organism_id"
    t.integer "project_id"
  end

  add_index "organisms_projects", ["organism_id", "project_id"], :name => "index_organisms_projects_on_organism_id_and_project_id"
  add_index "organisms_projects", ["project_id"], :name => "index_organisms_projects_on_project_id"

  create_table "people", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.string   "phone"
    t.string   "skype_name"
    t.string   "web_page"
    t.text     "description"
    t.integer  "avatar_id"
    t.integer  "status_id",                  :default => 0
    t.string   "first_letter", :limit => 10
    t.string   "uuid"
    t.integer  "roles_mask",                 :default => 0
    t.string   "orcid"
  end

  create_table "permissions", :force => true do |t|
    t.string   "contributor_type"
    t.integer  "contributor_id"
    t.integer  "policy_id"
    t.integer  "access_type",      :limit => 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "permissions", ["policy_id"], :name => "index_permissions_on_policy_id"

  create_table "phenotypes", :force => true do |t|
    t.text     "description"
    t.text     "comment"
    t.integer  "strain_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "deprecated_specimen_id"
  end

  create_table "policies", :force => true do |t|
    t.string   "name"
    t.integer  "sharing_scope", :limit => 1
    t.integer  "access_type",   :limit => 1
    t.boolean  "use_whitelist"
    t.boolean  "use_blacklist"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "posts", :force => true do |t|
    t.integer  "user_id"
    t.integer  "topic_id"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "forum_id"
    t.text     "body_html"
  end

  add_index "posts", ["forum_id", "created_at"], :name => "index_posts_on_forum_id"
  add_index "posts", ["topic_id", "created_at"], :name => "index_posts_on_topic_id"
  add_index "posts", ["user_id", "created_at"], :name => "index_posts_on_user_id"

  create_table "presentation_auth_lookup", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view",     :default => false
    t.boolean "can_manage",   :default => false
    t.boolean "can_edit",     :default => false
    t.boolean "can_download", :default => false
    t.boolean "can_delete",   :default => false
  end

  add_index "presentation_auth_lookup", ["user_id", "asset_id", "can_view"], :name => "index_presentation_user_id_asset_id_can_view"
  add_index "presentation_auth_lookup", ["user_id", "can_view"], :name => "index_presentation_auth_lookup_on_user_id_and_can_view"

  create_table "presentation_versions", :force => true do |t|
    t.integer  "presentation_id"
    t.integer  "version"
    t.text     "revision_comments"
    t.string   "contributor_type"
    t.integer  "contributor_id"
    t.string   "title"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_used_at"
    t.string   "first_letter",      :limit => 1
    t.text     "other_creators"
    t.string   "uuid"
    t.integer  "policy_id"
    t.string   "license"
  end

  create_table "presentation_versions_projects", :id => false, :force => true do |t|
    t.integer "project_id"
    t.integer "version_id"
  end

  create_table "presentations", :force => true do |t|
    t.string   "contributor_type"
    t.integer  "contributor_id"
    t.string   "title"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_used_at"
    t.integer  "version",                       :default => 1
    t.string   "first_letter",     :limit => 1
    t.text     "other_creators"
    t.string   "uuid"
    t.integer  "policy_id"
    t.string   "license"
  end

  create_table "presentations_projects", :id => false, :force => true do |t|
    t.integer "project_id"
    t.integer "presentation_id"
  end

  add_index "presentations_projects", ["presentation_id", "project_id"], :name => "index_presentations_projects_pres_proj_id"
  add_index "presentations_projects", ["project_id"], :name => "index_presentations_projects_on_project_id"

  create_table "programmes", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.integer  "avatar_id"
    t.string   "web_page"
    t.string   "first_letter",                :limit => 1
    t.string   "uuid"
    t.datetime "created_at",                                                  :null => false
    t.datetime "updated_at",                                                  :null => false
    t.text     "funding_details"
    t.boolean  "is_activated",                             :default => false
    t.text     "activation_rejection_reason"
  end

  create_table "project_descendants", :id => false, :force => true do |t|
    t.integer "ancestor_id"
    t.integer "descendant_id"
  end

  create_table "project_folder_assets", :force => true do |t|
    t.integer  "asset_id"
    t.string   "asset_type"
    t.integer  "project_folder_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "project_folders", :force => true do |t|
    t.integer  "project_id"
    t.string   "title"
    t.text     "description"
    t.integer  "parent_id"
    t.boolean  "editable",    :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "incoming",    :default => false
    t.boolean  "deletable",   :default => true
  end

  create_table "project_positions", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "project_subscriptions", :force => true do |t|
    t.integer "person_id"
    t.integer "project_id"
    t.string  "unsubscribed_types"
    t.string  "frequency"
  end

  add_index "project_subscriptions", ["person_id", "project_id"], :name => "index_project_subscriptions_on_person_id_and_project_id"

  create_table "projects", :force => true do |t|
    t.string   "title"
    t.string   "web_page"
    t.string   "wiki_page"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.integer  "avatar_id"
    t.integer  "default_policy_id"
    t.string   "first_letter",      :limit => 1
    t.string   "site_credentials"
    t.string   "site_root_uri"
    t.datetime "last_jerm_run"
    t.string   "uuid"
    t.integer  "programme_id"
    t.integer  "ancestor_id"
    t.integer  "parent_id"
  end

  create_table "projects_publications", :id => false, :force => true do |t|
    t.integer "project_id"
    t.integer "publication_id"
  end

  add_index "projects_publications", ["project_id"], :name => "index_projects_publications_on_project_id"
  add_index "projects_publications", ["publication_id", "project_id"], :name => "index_projects_publications_on_publication_id_and_project_id"

  create_table "projects_samples", :id => false, :force => true do |t|
    t.integer "project_id"
    t.integer "sample_id"
  end

  create_table "projects_sop_versions", :id => false, :force => true do |t|
    t.integer "project_id"
    t.integer "version_id"
  end

  create_table "projects_sops", :id => false, :force => true do |t|
    t.integer "project_id"
    t.integer "sop_id"
  end

  create_table "projects_strains", :id => false, :force => true do |t|
    t.integer "project_id"
    t.integer "strain_id"
  end

  create_table "projects_sweeps", :force => true do |t|
    t.integer "sweep_id"
    t.integer "project_id"
  end

  create_table "projects_taverna_player_runs", :id => false, :force => true do |t|
    t.integer "run_id"
    t.integer "project_id"
  end

  create_table "projects_workflow_versions", :id => false, :force => true do |t|
    t.integer "version_id"
    t.integer "project_id"
  end

  create_table "projects_workflows", :id => false, :force => true do |t|
    t.integer "workflow_id"
    t.integer "project_id"
  end

  create_table "publication_auth_lookup", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view",     :default => false
    t.boolean "can_manage",   :default => false
    t.boolean "can_edit",     :default => false
    t.boolean "can_download", :default => false
    t.boolean "can_delete",   :default => false
  end

  add_index "publication_auth_lookup", ["user_id", "asset_id", "can_view"], :name => "index_pub_user_id_asset_id_can_view"
  add_index "publication_auth_lookup", ["user_id", "can_view"], :name => "index_publication_auth_lookup_on_user_id_and_can_view"

  create_table "publication_author_orders", :force => true do |t|
    t.integer "order"
    t.integer "author_id"
    t.string  "author_type"
    t.integer "publication_id"
  end

  create_table "publication_authors", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.integer  "publication_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "author_index"
    t.integer  "person_id"
  end

  create_table "publications", :force => true do |t|
    t.integer  "pubmed_id"
    t.text     "title"
    t.text     "abstract"
    t.date     "published_date"
    t.string   "journal"
    t.string   "first_letter",     :limit => 1
    t.string   "contributor_type"
    t.integer  "contributor_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_used_at"
    t.string   "doi"
    t.string   "uuid"
    t.integer  "policy_id"
    t.integer  "publication_type",              :default => 1
    t.string   "citation"
  end

  add_index "publications", ["contributor_id", "contributor_type"], :name => "index_publications_on_contributor_id_and_contributor_type"

  create_table "recommended_model_environments", :force => true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reindexing_queues", :force => true do |t|
    t.string   "item_type"
    t.integer  "item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "relationship_types", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "relationships", :force => true do |t|
    t.string   "subject_type",      :null => false
    t.integer  "subject_id",        :null => false
    t.string   "predicate",         :null => false
    t.string   "other_object_type", :null => false
    t.integer  "other_object_id",   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "resource_publish_logs", :force => true do |t|
    t.string   "resource_type"
    t.integer  "resource_id"
    t.integer  "user_id"
    t.integer  "publish_state"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "comment"
  end

  add_index "resource_publish_logs", ["publish_state"], :name => "index_resource_publish_logs_on_publish_state"
  add_index "resource_publish_logs", ["resource_type", "resource_id"], :name => "index_resource_publish_logs_on_resource_type_and_resource_id"
  add_index "resource_publish_logs", ["user_id"], :name => "index_resource_publish_logs_on_user_id"

  create_table "sample_attribute_types", :force => true do |t|
    t.string   "title"
    t.string   "base_type"
    t.text     "regexp"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "sample_attributes", :force => true do |t|
    t.string   "title"
    t.integer  "sample_attribute_type_id"
    t.boolean  "required",                   :default => false
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
    t.integer  "pos"
    t.integer  "sample_type_id"
    t.integer  "unit_id"
    t.boolean  "is_title",                   :default => false
    t.integer  "template_column_index"
    t.string   "accessor_name"
    t.integer  "sample_controlled_vocab_id"
  end

  add_index "sample_attributes", ["sample_type_id"], :name => "index_sample_attributes_on_sample_type_id"
  add_index "sample_attributes", ["unit_id"], :name => "index_sample_attributes_on_unit_id"

  create_table "sample_auth_lookup", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view",     :default => false
    t.boolean "can_manage",   :default => false
    t.boolean "can_edit",     :default => false
    t.boolean "can_download", :default => false
    t.boolean "can_delete",   :default => false
  end

  add_index "sample_auth_lookup", ["user_id", "asset_id", "can_view"], :name => "index_sample_user_id_asset_id_can_view"
  add_index "sample_auth_lookup", ["user_id", "can_view"], :name => "index_sample_auth_lookup_on_user_id_and_can_view"

  create_table "sample_controlled_vocab_terms", :force => true do |t|
    t.string   "label"
    t.integer  "sample_controlled_vocab_id"
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
  end

  create_table "sample_controlled_vocabs", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "sample_types", :force => true do |t|
    t.string   "title"
    t.string   "uuid"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
    t.integer  "content_blob_id"
  end

  create_table "samples", :force => true do |t|
    t.string   "title"
    t.integer  "sample_type_id"
    t.text     "json_metadata"
    t.string   "uuid"
    t.integer  "contributor_id"
    t.integer  "policy_id"
    t.string   "contributor_type"
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.string   "first_letter",             :limit => 1
    t.text     "other_creators"
    t.integer  "originating_data_file_id"
  end

  create_table "saved_searches", :force => true do |t|
    t.integer  "user_id"
    t.text     "search_query"
    t.text     "search_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "include_external_search", :default => false
  end

  create_table "scales", :force => true do |t|
    t.string   "title"
    t.string   "key"
    t.integer  "pos",        :default => 1
    t.string   "image_name"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  create_table "scalings", :force => true do |t|
    t.integer  "scale_id"
    t.integer  "scalable_id"
    t.integer  "person_id"
    t.string   "scalable_type"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "settings", :force => true do |t|
    t.string   "var",                       :null => false
    t.text     "value"
    t.integer  "target_id"
    t.string   "target_type", :limit => 30
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "settings", ["target_type", "target_id", "var"], :name => "index_settings_on_target_type_and_target_id_and_var", :unique => true

  create_table "site_announcement_categories", :force => true do |t|
    t.string   "title"
    t.string   "icon_key"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "site_announcements", :force => true do |t|
    t.integer  "announcer_id"
    t.string   "announcer_type"
    t.string   "title"
    t.text     "body"
    t.integer  "site_announcement_category_id"
    t.boolean  "is_headline",                   :default => false
    t.datetime "expires_at"
    t.boolean  "show_in_feed",                  :default => true
    t.boolean  "email_notification",            :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "snapshots", :force => true do |t|
    t.string   "resource_type"
    t.integer  "resource_id"
    t.string   "doi"
    t.integer  "snapshot_number"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
    t.integer  "zenodo_deposition_id"
    t.string   "zenodo_record_url"
  end

  create_table "sop_auth_lookup", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view",     :default => false
    t.boolean "can_manage",   :default => false
    t.boolean "can_edit",     :default => false
    t.boolean "can_download", :default => false
    t.boolean "can_delete",   :default => false
  end

  add_index "sop_auth_lookup", ["user_id", "asset_id", "can_view"], :name => "index_sop_auth_lookup_on_user_id_and_asset_id_and_can_view"
  add_index "sop_auth_lookup", ["user_id", "can_view"], :name => "index_sop_auth_lookup_on_user_id_and_can_view"

  create_table "sop_deprecated_specimens", :force => true do |t|
    t.integer "deprecated_specimen_id"
    t.integer "sop_id"
    t.integer "sop_version"
  end

  create_table "sop_versions", :force => true do |t|
    t.integer  "sop_id"
    t.integer  "version"
    t.text     "revision_comments"
    t.string   "contributor_type"
    t.integer  "contributor_id"
    t.string   "title"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_used_at"
    t.string   "first_letter",      :limit => 1
    t.text     "other_creators"
    t.string   "uuid"
    t.integer  "policy_id"
    t.string   "doi"
    t.string   "license"
  end

  add_index "sop_versions", ["contributor_id", "contributor_type"], :name => "index_sop_versions_on_contributor_id_and_contributor_type"
  add_index "sop_versions", ["sop_id"], :name => "index_sop_versions_on_sop_id"

  create_table "sops", :force => true do |t|
    t.string   "contributor_type"
    t.integer  "contributor_id"
    t.string   "title"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_used_at"
    t.integer  "version",                       :default => 1
    t.string   "first_letter",     :limit => 1
    t.text     "other_creators"
    t.string   "uuid"
    t.integer  "policy_id"
    t.string   "doi"
    t.string   "license"
  end

  add_index "sops", ["contributor_id", "contributor_type"], :name => "index_sops_on_contributor_id_and_contributor_type"

  create_table "special_auth_codes", :force => true do |t|
    t.string   "code"
    t.date     "expiration_date"
    t.string   "asset_type"
    t.integer  "asset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "strain_auth_lookup", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view",     :default => false
    t.boolean "can_manage",   :default => false
    t.boolean "can_edit",     :default => false
    t.boolean "can_download", :default => false
    t.boolean "can_delete",   :default => false
  end

  add_index "strain_auth_lookup", ["user_id", "asset_id", "can_view"], :name => "index_strain_user_id_asset_id_can_view"
  add_index "strain_auth_lookup", ["user_id", "can_view"], :name => "index_strain_auth_lookup_on_user_id_and_can_view"

  create_table "strain_descendants", :id => false, :force => true do |t|
    t.integer "ancestor_id"
    t.integer "descendant_id"
  end

  create_table "strains", :force => true do |t|
    t.string   "title"
    t.integer  "organism_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id"
    t.string   "synonym"
    t.text     "comment"
    t.string   "provider_id"
    t.string   "provider_name"
    t.boolean  "is_dummy",         :default => false
    t.string   "contributor_type"
    t.integer  "contributor_id"
    t.integer  "policy_id"
    t.string   "uuid"
    t.string   "first_letter"
  end

  create_table "studied_factor_links", :force => true do |t|
    t.string   "substance_type"
    t.integer  "substance_id"
    t.integer  "studied_factor_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "studied_factors", :force => true do |t|
    t.integer  "measured_item_id"
    t.float    "start_value"
    t.float    "end_value"
    t.integer  "unit_id"
    t.float    "time_point"
    t.integer  "data_file_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "standard_deviation"
    t.integer  "data_file_version"
  end

  add_index "studied_factors", ["data_file_id"], :name => "index_studied_factors_on_data_file_id"

  create_table "studies", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.integer  "investigation_id"
    t.string   "experimentalists"
    t.datetime "begin_date"
    t.integer  "person_responsible_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_letter",          :limit => 1
    t.string   "uuid"
    t.integer  "policy_id"
    t.integer  "contributor_id"
    t.string   "contributor_type"
    t.text     "other_creators"
  end

  create_table "study_auth_lookup", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view",     :default => false
    t.boolean "can_manage",   :default => false
    t.boolean "can_edit",     :default => false
    t.boolean "can_download", :default => false
    t.boolean "can_delete",   :default => false
  end

  add_index "study_auth_lookup", ["user_id", "asset_id", "can_view"], :name => "index_study_auth_lookup_on_user_id_and_asset_id_and_can_view"
  add_index "study_auth_lookup", ["user_id", "can_view"], :name => "index_study_auth_lookup_on_user_id_and_can_view"

  create_table "subscriptions", :force => true do |t|
    t.integer  "person_id"
    t.integer  "subscribable_id"
    t.string   "subscribable_type"
    t.string   "subscription_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "project_subscription_id"
  end

  create_table "suggested_assay_types", :force => true do |t|
    t.string   "label"
    t.string   "ontology_uri"
    t.integer  "contributor_id"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.integer  "parent_id"
  end

  create_table "suggested_technology_types", :force => true do |t|
    t.string   "label"
    t.string   "ontology_uri"
    t.integer  "contributor_id"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.integer  "parent_id"
  end

  create_table "sweep_auth_lookup", :force => true do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view"
    t.boolean "can_manage"
    t.boolean "can_edit"
    t.boolean "can_download"
    t.boolean "can_delete"
  end

  add_index "sweep_auth_lookup", ["user_id", "asset_id", "can_view"], :name => "index_sweep_auth_lookup_on_user_id_and_asset_id_and_can_view"
  add_index "sweep_auth_lookup", ["user_id", "can_view"], :name => "index_sweep_auth_lookup_on_user_id_and_can_view"

  create_table "sweeps", :force => true do |t|
    t.string   "name"
    t.integer  "contributor_id"
    t.integer  "workflow_id"
    t.integer  "workflow_version",              :default => 1
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
    t.string   "contributor_type"
    t.text     "description"
    t.string   "uuid"
    t.string   "first_letter",     :limit => 1
    t.integer  "policy_id"
  end

  create_table "synonyms", :force => true do |t|
    t.string   "name"
    t.integer  "substance_id"
    t.string   "substance_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "synonyms", ["substance_id", "substance_type"], :name => "index_synonyms_on_substance_id_and_substance_type"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "taggable_type"
    t.string   "context"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "taverna_player_interactions", :force => true do |t|
    t.boolean  "replied",                        :default => false
    t.integer  "run_id"
    t.datetime "created_at",                                        :null => false
    t.datetime "updated_at",                                        :null => false
    t.boolean  "displayed",                      :default => false
    t.text     "page"
    t.string   "feed_reply"
    t.text     "data",       :limit => 16777215
    t.string   "serial"
    t.string   "page_uri"
  end

  add_index "taverna_player_interactions", ["run_id", "replied"], :name => "index_taverna_player_interactions_on_run_id_and_replied"
  add_index "taverna_player_interactions", ["run_id", "serial"], :name => "index_taverna_player_interactions_on_run_id_and_serial"
  add_index "taverna_player_interactions", ["run_id"], :name => "index_taverna_player_interactions_on_run_id"

  create_table "taverna_player_run_auth_lookup", :force => true do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view"
    t.boolean "can_manage"
    t.boolean "can_edit"
    t.boolean "can_download"
    t.boolean "can_delete"
  end

  add_index "taverna_player_run_auth_lookup", ["user_id", "asset_id", "can_view"], :name => "tav_player_run_user_asset_view_index"
  add_index "taverna_player_run_auth_lookup", ["user_id", "can_view"], :name => "tav_player_run_user_view_index"

  create_table "taverna_player_run_ports", :force => true do |t|
    t.string   "name"
    t.string   "value"
    t.string   "port_type"
    t.integer  "run_id"
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.integer  "depth",             :default => 0
    t.text     "metadata"
    t.integer  "data_file_id"
    t.integer  "data_file_version"
  end

  add_index "taverna_player_run_ports", ["run_id", "name"], :name => "index_taverna_player_run_ports_on_run_id_and_name"
  add_index "taverna_player_run_ports", ["run_id"], :name => "index_taverna_player_run_ports_on_run_id"

  create_table "taverna_player_runs", :force => true do |t|
    t.string   "run_id"
    t.string   "saved_state",                     :default => "pending", :null => false
    t.datetime "create_time"
    t.datetime "start_time"
    t.datetime "finish_time"
    t.integer  "workflow_id",                                            :null => false
    t.datetime "created_at",                                             :null => false
    t.datetime "updated_at",                                             :null => false
    t.string   "status_message_key"
    t.string   "results_file_name"
    t.integer  "results_file_size"
    t.boolean  "embedded",                        :default => false
    t.boolean  "stop",                            :default => false
    t.string   "log_file_name"
    t.integer  "log_file_size"
    t.string   "name",                            :default => "None"
    t.integer  "delayed_job_id"
    t.integer  "sweep_id"
    t.integer  "contributor_id"
    t.integer  "policy_id"
    t.string   "contributor_type"
    t.text     "failure_message"
    t.integer  "parent_id"
    t.string   "uuid"
    t.string   "first_letter",       :limit => 1
    t.text     "description"
    t.integer  "user_id"
    t.integer  "workflow_version",                :default => 1
    t.boolean  "reported",                        :default => false
  end

  add_index "taverna_player_runs", ["parent_id"], :name => "index_taverna_player_runs_on_parent_id"
  add_index "taverna_player_runs", ["user_id"], :name => "index_taverna_player_runs_on_user_id"
  add_index "taverna_player_runs", ["workflow_id"], :name => "index_taverna_player_runs_on_workflow_id"

  create_table "taverna_player_service_credentials", :force => true do |t|
    t.string   "uri",         :null => false
    t.string   "name"
    t.text     "description"
    t.string   "login"
    t.string   "password"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "taverna_player_service_credentials", ["uri"], :name => "index_taverna_player_service_credentials_on_uri"

  create_table "taverna_player_workflows", :force => true do |t|
    t.string   "title"
    t.string   "author"
    t.text     "description"
    t.string   "file"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "text_value_versions", :force => true do |t|
    t.integer  "text_value_id",                          :null => false
    t.integer  "version",                                :null => false
    t.integer  "version_creator_id"
    t.text     "text",               :limit => 16777215, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "text_value_versions", ["text_value_id"], :name => "index_text_value_versions_on_text_value_id"

  create_table "text_values", :force => true do |t|
    t.integer  "version"
    t.integer  "version_creator_id"
    t.text     "text",               :limit => 16777215, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tissue_and_cell_types", :force => true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "topics", :force => true do |t|
    t.integer  "forum_id"
    t.integer  "user_id"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "hits",         :default => 0
    t.integer  "sticky",       :default => 0
    t.integer  "posts_count",  :default => 0
    t.datetime "replied_at"
    t.boolean  "locked",       :default => false
    t.integer  "replied_by"
    t.integer  "last_post_id"
  end

  add_index "topics", ["forum_id", "replied_at"], :name => "index_topics_on_forum_id_and_replied_at"
  add_index "topics", ["forum_id", "sticky", "replied_at"], :name => "index_topics_on_sticky_and_replied_at"
  add_index "topics", ["forum_id"], :name => "index_topics_on_forum_id"

  create_table "trash_records", :force => true do |t|
    t.string   "trashable_type"
    t.integer  "trashable_id"
    t.binary   "data",           :limit => 16777215
    t.datetime "created_at"
  end

  add_index "trash_records", ["created_at", "trashable_type"], :name => "index_trash_records_on_created_at_and_trashable_type"
  add_index "trash_records", ["trashable_type", "trashable_id"], :name => "index_trash_records_on_trashable_type_and_trashable_id"

  create_table "units", :force => true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "symbol"
    t.string   "comment"
    t.boolean  "factors_studied", :default => true
    t.integer  "order"
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "activation_code",           :limit => 40
    t.datetime "activated_at"
    t.integer  "person_id"
    t.string   "reset_password_code"
    t.datetime "reset_password_code_until"
    t.integer  "posts_count",                             :default => 0
    t.datetime "last_seen_at"
    t.string   "uuid"
  end

  create_table "work_groups", :force => true do |t|
    t.string   "name"
    t.integer  "institution_id"
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "work_groups", ["project_id"], :name => "index_work_groups_on_project_id"

  create_table "workflow_auth_lookup", :force => true do |t|
    t.integer "user_id"
    t.integer "asset_id"
    t.boolean "can_view"
    t.boolean "can_manage"
    t.boolean "can_edit"
    t.boolean "can_download"
    t.boolean "can_delete"
  end

  add_index "workflow_auth_lookup", ["user_id", "asset_id", "can_view"], :name => "index_workflow_auth_lookup_on_user_id_and_asset_id_and_can_view"
  add_index "workflow_auth_lookup", ["user_id", "can_view"], :name => "index_workflow_auth_lookup_on_user_id_and_can_view"

  create_table "workflow_categories", :force => true do |t|
    t.string "name"
  end

  create_table "workflow_input_port_types", :force => true do |t|
    t.string "name"
  end

  create_table "workflow_input_ports", :force => true do |t|
    t.string  "name"
    t.text    "description"
    t.integer "port_type_id"
    t.text    "example_value"
    t.integer "example_data_file_id"
    t.integer "workflow_id"
    t.integer "workflow_version"
    t.string  "mime_type"
  end

  create_table "workflow_output_port_types", :force => true do |t|
    t.string "name"
  end

  create_table "workflow_output_ports", :force => true do |t|
    t.string  "name"
    t.text    "description"
    t.integer "port_type_id"
    t.text    "example_value"
    t.integer "example_data_file_id"
    t.integer "workflow_id"
    t.integer "workflow_version"
    t.string  "mime_type"
  end

  create_table "workflow_versions", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.integer  "category_id"
    t.integer  "contributor_id"
    t.string   "contributor_type"
    t.string   "uuid"
    t.integer  "policy_id"
    t.text     "other_creators"
    t.string   "first_letter",       :limit => 1
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.datetime "last_used_at"
    t.integer  "workflow_id"
    t.text     "revision_comments"
    t.integer  "version"
    t.boolean  "sweepable"
    t.string   "myexperiment_link"
    t.string   "documentation_link"
    t.string   "doi"
  end

  create_table "workflows", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.integer  "category_id"
    t.integer  "contributor_id"
    t.string   "contributor_type"
    t.string   "uuid"
    t.integer  "policy_id"
    t.text     "other_creators"
    t.string   "first_letter",       :limit => 1
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.datetime "last_used_at"
    t.integer  "version"
    t.boolean  "sweepable"
    t.string   "myexperiment_link"
    t.string   "documentation_link"
    t.string   "doi"
  end

  create_table "worksheets", :force => true do |t|
    t.integer "content_blob_id"
    t.integer "last_row"
    t.integer "last_column"
    t.integer "sheet_number"
  end

end
