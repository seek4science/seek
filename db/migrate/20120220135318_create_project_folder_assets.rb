class CreateProjectFolderAssets < ActiveRecord::Migration
  def self.up
    create_table :project_folder_assets do |t|
      t.integer :asset_id
      t.string :asset_type
      t.integer :project_folder_id

      t.timestamps
    end
  end

  def self.down
    drop_table :project_folder_assets
  end
end
