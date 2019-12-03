class CreateDefaultProjectFolders < ActiveRecord::Migration[5.2]
  def change
    create_table :default_project_folders do |t|
      t.string "title"
      t.text "description"

      t.timestamps
    end
  end
end
