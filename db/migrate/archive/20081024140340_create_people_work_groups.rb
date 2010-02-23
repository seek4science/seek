class CreatePeopleWorkGroups < ActiveRecord::Migration
  def self.up
    create_table :people_work_groups, :id => false, :force => true do |t|
      t.integer :person_id
      t.integer :work_group_id
    end

  end

  def self.down
    drop_table :people_work_groups
  end
end
