class AddImportedFromFieldsToModelVersion < ActiveRecord::Migration
  def self.up
    add_column :model_versions, :imported_source, :string, :default=>nil
    add_column :model_versions, :imported_url, :string, :default=>nil
  end

  def self.down
    remove_column :model_versions, :imported_source
    remove_column :model_versions, :imported_url
  end
end
