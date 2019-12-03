class CreateOtherProjectFiles < ActiveRecord::Migration[5.2]
  def change
    create_table :other_project_files do |t|
      t.string :title
      t.text :description
      t.string :uuid
      t.integer :default_project_folders_id

      t.timestamps
    end
  end
end
