class DropWorkflowRelatedTables < ActiveRecord::Migration
  def change
    # Workflows
    drop_table "workflows" do |t|
      t.string   "title",              limit: 255
      t.text     "description",        limit: 65535
      t.integer  "category_id",        limit: 4
      t.integer  "contributor_id",     limit: 4
      t.string   "contributor_type",   limit: 255
      t.string   "uuid",               limit: 255
      t.integer  "policy_id",          limit: 4
      t.text     "other_creators",     limit: 65535
      t.string   "first_letter",       limit: 1
      t.datetime "created_at",                       null: false
      t.datetime "updated_at",                       null: false
      t.datetime "last_used_at"
      t.integer  "version",            limit: 4
      t.boolean  "sweepable"
      t.string   "myexperiment_link",  limit: 255
      t.string   "documentation_link", limit: 255
      t.string   "doi",                limit: 255
    end

    drop_table "workflow_versions" do |t|
      t.string   "title",              limit: 255
      t.text     "description",        limit: 65535
      t.integer  "category_id",        limit: 4
      t.integer  "contributor_id",     limit: 4
      t.string   "contributor_type",   limit: 255
      t.string   "uuid",               limit: 255
      t.integer  "policy_id",          limit: 4
      t.text     "other_creators",     limit: 65535
      t.string   "first_letter",       limit: 1
      t.datetime "created_at",                       null: false
      t.datetime "updated_at",                       null: false
      t.datetime "last_used_at"
      t.integer  "workflow_id",        limit: 4
      t.text     "revision_comments",  limit: 65535
      t.integer  "version",            limit: 4
      t.boolean  "sweepable"
      t.string   "myexperiment_link",  limit: 255
      t.string   "documentation_link", limit: 255
      t.string   "doi",                limit: 255
    end

    drop_table "workflow_auth_lookup" do |t|
      t.integer "user_id",      limit: 4
      t.integer "asset_id",     limit: 4
      t.boolean "can_view"
      t.boolean "can_manage"
      t.boolean "can_edit"
      t.boolean "can_download"
      t.boolean "can_delete"
    end

    drop_table "workflow_categories" do |t|
      t.string "name", limit: 255
    end

    drop_table "workflow_input_port_types" do |t|
      t.string "name", limit: 255
    end

    drop_table "workflow_input_ports" do |t|
      t.string  "name",                 limit: 255
      t.text    "description",          limit: 65535
      t.integer "port_type_id",         limit: 4
      t.text    "example_value",        limit: 65535
      t.integer "example_data_file_id", limit: 4
      t.integer "workflow_id",          limit: 4
      t.integer "workflow_version",     limit: 4
      t.string  "mime_type",            limit: 255
    end

    drop_table "workflow_output_port_types" do |t|
      t.string "name", limit: 255
    end

    drop_table "workflow_output_ports" do |t|
      t.string  "name",                 limit: 255
      t.text    "description",          limit: 65535
      t.integer "port_type_id",         limit: 4
      t.text    "example_value",        limit: 65535
      t.integer "example_data_file_id", limit: 4
      t.integer "workflow_id",          limit: 4
      t.integer "workflow_version",     limit: 4
      t.string  "mime_type",            limit: 255
    end

    # Taverna Player
    drop_table "taverna_player_interactions" do |t|
      t.boolean  "replied",                     default: false
      t.integer  "run_id",     limit: 4
      t.datetime "created_at",                                  null: false
      t.datetime "updated_at",                                  null: false
      t.boolean  "displayed",                   default: false
      t.text     "page",       limit: 65535
      t.string   "feed_reply", limit: 255
      t.text     "data",       limit: 16777215
      t.string   "serial",     limit: 255
      t.string   "page_uri",   limit: 255
    end

    drop_table "taverna_player_run_auth_lookup" do |t|
      t.integer "user_id",      limit: 4
      t.integer "asset_id",     limit: 4
      t.boolean "can_view"
      t.boolean "can_manage"
      t.boolean "can_edit"
      t.boolean "can_download"
      t.boolean "can_delete"
    end

    drop_table "taverna_player_run_ports" do |t|
      t.string   "name",              limit: 255
      t.string   "value",             limit: 255
      t.string   "port_type",         limit: 255
      t.integer  "run_id",            limit: 4
      t.datetime "created_at",                                  null: false
      t.datetime "updated_at",                                  null: false
      t.string   "file_file_name",    limit: 255
      t.string   "file_content_type", limit: 255
      t.integer  "file_file_size",    limit: 4
      t.datetime "file_updated_at"
      t.integer  "depth",             limit: 4,     default: 0
      t.text     "metadata",          limit: 65535
      t.integer  "data_file_id",      limit: 4
      t.integer  "data_file_version", limit: 4
    end

    drop_table "taverna_player_runs" do |t|
      t.string   "run_id",             limit: 255
      t.string   "saved_state",        limit: 255,   default: "pending", null: false
      t.datetime "create_time"
      t.datetime "start_time"
      t.datetime "finish_time"
      t.integer  "workflow_id",        limit: 4,                         null: false
      t.datetime "created_at",                                           null: false
      t.datetime "updated_at",                                           null: false
      t.string   "status_message_key", limit: 255
      t.string   "results_file_name",  limit: 255
      t.integer  "results_file_size",  limit: 4
      t.boolean  "embedded",                         default: false
      t.boolean  "stop",                             default: false
      t.string   "log_file_name",      limit: 255
      t.integer  "log_file_size",      limit: 4
      t.string   "name",               limit: 255,   default: "None"
      t.integer  "delayed_job_id",     limit: 4
      t.integer  "sweep_id",           limit: 4
      t.integer  "contributor_id",     limit: 4
      t.integer  "policy_id",          limit: 4
      t.string   "contributor_type",   limit: 255
      t.text     "failure_message",    limit: 65535
      t.integer  "parent_id",          limit: 4
      t.string   "uuid",               limit: 255
      t.string   "first_letter",       limit: 1
      t.text     "description",        limit: 65535
      t.integer  "user_id",            limit: 4
      t.integer  "workflow_version",   limit: 4,     default: 1
      t.boolean  "reported",                         default: false
    end

    drop_table "taverna_player_service_credentials" do |t|
      t.string   "uri",         limit: 255,   null: false
      t.string   "name",        limit: 255
      t.text     "description", limit: 65535
      t.string   "login",       limit: 255
      t.string   "password",    limit: 255
      t.datetime "created_at",                null: false
      t.datetime "updated_at",                null: false
    end

    drop_table "taverna_player_workflows" do |t|
      t.string   "title",       limit: 255
      t.string   "author",      limit: 255
      t.text     "description", limit: 65535
      t.string   "file",        limit: 255
      t.datetime "created_at",                null: false
      t.datetime "updated_at",                null: false
    end

    # Sweeps
    drop_table "sweep_auth_lookup" do |t|
      t.integer "user_id",      limit: 4
      t.integer "asset_id",     limit: 4
      t.boolean "can_view"
      t.boolean "can_manage"
      t.boolean "can_edit"
      t.boolean "can_download"
      t.boolean "can_delete"
    end

    drop_table "sweeps" do |t|
      t.string   "name",             limit: 255
      t.integer  "contributor_id",   limit: 4
      t.integer  "workflow_id",      limit: 4
      t.integer  "workflow_version", limit: 4,     default: 1
      t.datetime "created_at",                                 null: false
      t.datetime "updated_at",                                 null: false
      t.string   "contributor_type", limit: 255
      t.text     "description",      limit: 65535
      t.string   "uuid",             limit: 255
      t.string   "first_letter",     limit: 1
      t.integer  "policy_id",        limit: 4
    end

    # Project associations
    drop_table "projects_sweeps" do |t|
      t.integer "sweep_id",   limit: 4
      t.integer "project_id", limit: 4
    end

    drop_table "projects_taverna_player_runs", id: false do |t|
      t.integer "run_id",     limit: 4
      t.integer "project_id", limit: 4
    end

    drop_table "projects_workflow_versions", id: false do |t|
      t.integer "version_id", limit: 4
      t.integer "project_id", limit: 4
    end

    drop_table "projects_workflows", id: false do |t|
      t.integer "workflow_id", limit: 4
      t.integer "project_id",  limit: 4
    end
  end
end
