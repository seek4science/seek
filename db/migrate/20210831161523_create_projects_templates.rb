class CreateProjectsTemplates < ActiveRecord::Migration[5.2]
  def change
    create_table :projects_templates do |t|
      t.references :template
      t.references :project
    end
  end
end
