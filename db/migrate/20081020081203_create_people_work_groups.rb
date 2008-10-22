class CreatePeopleWorkGroups < ActiveRecord::Migration
  def self.up
    drop_table :work_groups_people
    create_table :people_work_groups, :id=>false do |t|
      t.integer :person_id
      t.integer :work_group_id
    end
  end

  def self.down
    drop_table :people_work_groups
    create_table :work_groups_people, :id => false, :force => true do |t|
    t.integer :person_id
    t.integer :group_id
  end
  end
end
