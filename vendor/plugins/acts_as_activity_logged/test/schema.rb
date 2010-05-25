ActiveRecord::Schema.define(:version => 0) do
  create_table :users, :force => true do |t|
    t.column :name, :string
    t.column :username, :string
    t.column :password, :string
    t.column :activated, :boolean
    t.column :logins, :integer, :default => 0
    t.column :created_at, :datetime
    t.column :updated_at, :datetime
  end
  
  create_table :activity_logs, :force => true do |t|
    t.column :user_id, :integer
    t.column :activity_loggable_type, :string
    t.column :activity_loggable_id, :integer
    t.column :action, :string
    t.column :created_at, :datetime
    t.column :culprit_id, :integer
    t.column :culprit_type, :string
    t.column :referenced_id, :integer
    t.column :referenced_type, :string
  end
end