class DropPeopleWorkGroups < ActiveRecord::Migration
  def self.up
    drop_table :people_work_groups
  end

  def self.down
    create_table :people_work_groups, :id => false, :force => true do |t|
      t.integer :person_id
      t.integer :work_group_id
    end
  end
end
