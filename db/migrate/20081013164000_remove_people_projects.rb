class RemovePeopleProjects < ActiveRecord::Migration
  def self.up
    drop_table :people_projects
  end

  def self.down
    create_table :people_projects, :id=>false do |t|
      t.integer :person_id
      t.integer :project_id
    end
  end
end
