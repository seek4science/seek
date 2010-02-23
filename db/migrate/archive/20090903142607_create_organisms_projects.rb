class CreateOrganismsProjects < ActiveRecord::Migration
  def self.up
    create_table :organisms_projects,:id=>false do |t|
      t.integer :organism_id
      t.integer :project_id
    end
  end

  def self.down
    drop_table :organisms_projects
  end
end
