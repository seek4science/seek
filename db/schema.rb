# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100416140944) do

  create_table "assay_assets", :force => true do |t|
    t.integer  "assay_id"
    t.integer  "asset_id"
    t.integer  "version"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "relationship_type_id"
  end

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
    t.integer  "phenotype_id"
    t.integer  "genotype_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "assay_types", :force => true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "assay_types_edges", :id => false, :force => true do |t|
    t.integer "parent_id"
    t.integer "child_id"
  end

  create_table "assays", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.integer  "assay_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "technology_type_id"
    t.integer  "study_id"
    t.integer  "owner_id"
    t.string   "first_letter",       :limit => 1
    t.integer  "assay_class_id"
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

  create_table "assets_creators", :id => false, :force => true do |t|
    t.integer "asset_id"
    t.integer "creator_id"
  end

  create_table "avatars", :force => true do |t|
    t.string   "owner_type"
    t.integer  "owner_id"
    t.string   "original_filename"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bioportal_concepts", :force => true do |t|
    t.integer "ontology_id"
    t.integer "ontology_version_id"
    t.string  "concept_uri"
    t.text    "cached_concept_yaml"
    t.integer "conceptable_id"
    t.string  "conceptable_type"
  end

  create_table "content_blobs", :force => true do |t|
    t.binary "data",   :limit => 2147483647
    t.string "md5sum"
    t.string "url"
  end

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

  create_table "data_file_versions", :force => true do |t|
    t.integer  "data_file_id"
    t.integer  "version"
    t.text     "revision_comments"
    t.string   "contributor_type"
    t.integer  "contributor_id"
    t.string   "title"
    t.text     "description"
    t.string   "original_filename"
    t.string   "content_type"
    t.integer  "content_blob_id"
    t.integer  "template_id"
    t.datetime "last_used_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_letter",      :limit => 1
  end

  create_table "data_files", :force => true do |t|
    t.string   "contributor_type"
    t.integer  "contributor_id"
    t.string   "title"
    t.text     "description"
    t.string   "original_filename"
    t.string   "content_type"
    t.integer  "content_blob_id"
    t.integer  "template_id"
    t.datetime "last_used_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "version",                        :default => 1
    t.string   "first_letter",      :limit => 1
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

  create_table "forums", :force => true do |t|
    t.string  "name"
    t.string  "description"
    t.integer "topics_count",     :default => 0
    t.integer "posts_count",      :default => 0
    t.integer "position"
    t.text    "description_html"
  end

  create_table "group_memberships", :force => true do |t|
    t.integer  "person_id"
    t.integer  "work_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "group_memberships_roles", :id => false, :force => true do |t|
    t.integer "group_membership_id"
    t.integer "role_id"
  end

  create_table "institutions", :force => true do |t|
    t.string   "name"
    t.text     "address"
    t.string   "city"
    t.string   "web_page"
    t.string   "country"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "avatar_id"
    t.string   "first_letter", :limit => 1
  end

  create_table "investigations", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_letter", :limit => 1
  end

  create_table "measured_items", :force => true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "model_formats", :force => true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.string   "original_filename"
    t.integer  "content_blob_id"
    t.string   "content_type"
    t.integer  "recommended_environment_id"
    t.text     "result_graph"
    t.datetime "last_used_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "organism_id"
    t.integer  "model_type_id"
    t.integer  "model_format_id"
    t.string   "first_letter",               :limit => 1
  end

  create_table "models", :force => true do |t|
    t.string   "contributor_type"
    t.integer  "contributor_id"
    t.string   "title"
    t.text     "description"
    t.string   "original_filename"
    t.integer  "content_blob_id"
    t.string   "content_type"
    t.integer  "recommended_environment_id"
    t.text     "result_graph"
    t.datetime "last_used_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "organism_id"
    t.integer  "model_type_id"
    t.integer  "model_format_id"
    t.integer  "version",                                 :default => 1
    t.string   "first_letter",               :limit => 1
  end

  create_table "moderatorships", :force => true do |t|
    t.integer "forum_id"
    t.integer "user_id"
  end

  add_index "moderatorships", ["forum_id"], :name => "index_moderatorships_on_forum_id"

  create_table "monitorships", :force => true do |t|
    t.integer "topic_id"
    t.integer "user_id"
    t.boolean "active",   :default => true
  end

  create_table "organisms", :force => true do |t|
    t.string   "title"
    t.integer  "ncbi_id"
    t.string   "strain"
    t.string   "genotype"
    t.string   "phenotype"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "organisms_projects", :id => false, :force => true do |t|
    t.integer "organism_id"
    t.integer "project_id"
  end

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
    t.boolean  "is_pal",                     :default => false
    t.string   "first_letter", :limit => 10
  end

  create_table "permissions", :force => true do |t|
    t.string   "contributor_type"
    t.integer  "contributor_id"
    t.integer  "policy_id"
    t.integer  "access_type",      :limit => 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "policies", :force => true do |t|
    t.string   "name"
    t.integer  "sharing_scope",      :limit => 1
    t.integer  "access_type",        :limit => 1
    t.boolean  "use_custom_sharing"
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

  create_table "projects", :force => true do |t|
    t.string   "name"
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
  end

  create_table "publication_authors", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.integer  "publication_id"
    t.datetime "created_at"
    t.datetime "updated_at"
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
  end

  create_table "recommended_model_environments", :force => true do |t|
    t.string   "title"
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
    t.string   "subject_type", :null => false
    t.integer  "subject_id",   :null => false
    t.string   "predicate",    :null => false
    t.string   "object_type",  :null => false
    t.integer  "object_id",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "saved_searches", :force => true do |t|
    t.integer  "user_id"
    t.text     "search_query"
    t.text     "search_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sop_versions", :force => true do |t|
    t.integer  "sop_id"
    t.integer  "version"
    t.text     "revision_comments"
    t.string   "contributor_type"
    t.integer  "contributor_id"
    t.string   "title"
    t.text     "description"
    t.string   "original_filename"
    t.string   "content_type"
    t.integer  "content_blob_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_used_at"
    t.string   "first_letter",      :limit => 1
  end

  create_table "sops", :force => true do |t|
    t.string   "contributor_type"
    t.integer  "contributor_id"
    t.string   "title"
    t.text     "description"
    t.string   "original_filename"
    t.string   "content_type"
    t.integer  "content_blob_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_used_at"
    t.integer  "version",                        :default => 1
    t.string   "first_letter",      :limit => 1
  end

  create_table "strains", :force => true do |t|
    t.string   "title"
    t.integer  "organism_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "studied_factors", :force => true do |t|
    t.integer  "measured_item_id"
    t.float    "start_value"
    t.float    "end_value"
    t.integer  "unit_id"
    t.integer  "time_point"
    t.integer  "data_file_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "standard_deviation"
    t.integer  "data_file_version"
  end

  create_table "studies", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.integer  "investigation_id"
    t.string   "experimentalists"
    t.datetime "begin_date"
    t.integer  "person_responsible_id"
    t.integer  "organism_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_letter",          :limit => 1
  end

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

  create_table "technology_types", :force => true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "technology_types_edges", :id => false, :force => true do |t|
    t.integer "parent_id"
    t.integer "child_id"
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
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "activation_code",           :limit => 40
    t.datetime "activated_at"
    t.integer  "person_id"
    t.boolean  "is_admin",                                :default => false
    t.boolean  "can_edit_projects",                       :default => false
    t.boolean  "can_edit_institutions",                   :default => false
    t.string   "reset_password_code"
    t.datetime "reset_password_code_until"
    t.integer  "posts_count",                             :default => 0
    t.datetime "last_seen_at"
  end

  create_table "work_groups", :force => true do |t|
    t.string   "name"
    t.integer  "institution_id"
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
