class CreateProjectsSampleTypes < ActiveRecord::Migration
  def up
    create_table :projects_sample_types,:id => false do |t|
      t.integer :project_id
      t.integer :sample_type_id
    end
    add_index :projects_sample_types, [:sample_type_id, :project_id], :name => :index_projects_sample_types_on_sample_type_id_and_project_id
    add_index :projects_sample_types, [:project_id], :name => :index_projects_sample_types_on_project_id
  end

  def down
    drop_table :projects_sample_types
  end
end
