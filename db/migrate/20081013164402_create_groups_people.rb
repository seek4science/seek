class CreateGroupsPeople < ActiveRecord::Migration
  def self.up
    create_table :groups_people, :id=>false do |t|
      t.integer :person_id
      t.integer :group_id
    end
  end

  def self.down
    drop_table :groups_people
  end
end
