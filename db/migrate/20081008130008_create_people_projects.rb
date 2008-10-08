class CreatePeopleProjects < ActiveRecord::Migration
  def self.up
    create_table :people_projects, :id=>false do |t|
      t.integer :person_id, :null=>false
      t.integer :project_id, :null=>false

      t.timestamps
    end
  end

  def self.down
    drop_table :people_projects
  end
end
