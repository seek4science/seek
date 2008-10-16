class RemoveLinksBetweenGroupsAndProjects < ActiveRecord::Migration
  def self.up
    drop_table :groups_projects
  end

  def self.down
    create_table :groups_projects, :id=>false do |t|
      t.integer :group_id
      t.integer :project_id
    end
  end
end
