class <%= class_name %> < ActiveRecord::Migration
  # original migration was suitable only for Rails2.0, so updated to
  # work with Rails 1.2.6 as well
  
  def self.up
    create_table :activity_logs do |t|
      t.column :action, :string
      t.column :format, :string
      t.column :activity_loggable_type, :string
      t.column :activity_loggable_id, :integer
      t.column :culprit_type, :string
      t.column :culprit_id, :integer
      t.column :referenced_type, :string
      t.column :referenced_id, :integer
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :http_referer, :string
      t.column :user_agent, :string
      t.column :data, :text, :limit => 1.megabyte
    end
    
    add_index :activity_logs, [ "action" ], :name => "act_logs_action_index"
    add_index :activity_logs, [ "activity_loggable_type", "activity_loggable_id" ], :name => "act_logs_act_loggable_index"
    add_index :activity_logs, [ "culprit_type", "culprit_id" ], :name => "act_logs_culprit_index"
    add_index :activity_logs, [ "referenced_type", "referenced_id" ], :name => "act_logs_referenced_index"
    add_index :activity_logs, [ "format" ], :name => "act_logs_format_index"
  end

  def self.down
    drop_table :activity_logs
  end
end