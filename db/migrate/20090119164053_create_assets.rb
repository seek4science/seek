class CreateAssets < ActiveRecord::Migration
  def self.up
    create_table :assets do |t|
      t.column :contributor_type, :string
      t.column :contributor_id,   :integer
      
      t.column :project_id,       :integer
      
      t.column :resource_type,    :string
      t.column :resource_id,      :integer
      
      t.column :source_type,      :string
      t.column :sorce_id,         :integer
      t.column :quality,          :string
      
      t.column :policy_id,        :integer
      
      t.timestamps
      t.column :last_used_at,     :datetime
    end
  end

  def self.down
    drop_table :assets
  end
end
