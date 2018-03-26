class RemoveTemplateNameFromDataFiles < ActiveRecord::Migration
  def self.up
    remove_column :data_files, :template_name
    remove_column :data_file_versions, :template_name
  end

  def self.down
    add_column :data_files, :template_name, :string, :default=> 'none'
    add_column :data_file_versions, :template_name, :string, :default=> 'none'
  end
end
