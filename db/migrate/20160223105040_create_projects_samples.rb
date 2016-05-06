class CreateProjectsSamples < ActiveRecord::Migration
  def change
    create_table :projects_samples,:id=>false do |t|
      t.integer :project_id
      t.integer :sample_id
    end
  end

end
