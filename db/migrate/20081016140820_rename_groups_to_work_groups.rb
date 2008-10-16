class RenameGroupsToWorkGroups < ActiveRecord::Migration
  def self.up
    rename_table :groups, :work_groups
    rename_table :groups_people, :work_groups_people
  end

  def self.down
    rename_table :work_groups, :groups
    rename_table :work_groups_people, :groups_people
  end
end
