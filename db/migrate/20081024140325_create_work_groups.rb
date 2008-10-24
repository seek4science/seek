class CreateWorkGroups < ActiveRecord::Migration
  def self.up
    create_table :work_groups, :force => true do |t|
      t.string   :name
      t.integer  :institution_id, :limit => 11
      t.integer  :project_id,     :limit => 11
    
      t.timestamps
    end


  end

  def self.down
    drop_table :work_groups
  end
end
