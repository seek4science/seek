class CreateProjectFolders < ActiveRecord::Migration
  def self.up
    create_table :project_folders do |t|
      t.integer :project_id
      t.string :title
      t.text :description
      t.integer :parent_id
      t.boolean :editable, :default=>true

      t.timestamps
    end
  end

  def self.down
    drop_table :project_folders
  end
end
