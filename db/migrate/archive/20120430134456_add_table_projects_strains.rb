class AddTableProjectsStrains < ActiveRecord::Migration
  def self.up
    create_table :projects_strains, :id => false, :force => true do |t|
        t.integer "project_id"
        t.integer "strain_id"
    end
  end

  def self.down
    drop_table :projects_strains
  end
end
