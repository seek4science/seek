class CreateGroupsProjects < ActiveRecord::Migration
  def self.up
    create_table :groups_projects, :id=>false do |t|
      t.integer :group_id
      t.integer :project_id
    end
  end

  def self.down
    drop_table :groups_projects
  end
end
