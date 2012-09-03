class AddTemplateInformationToDataFiles < ActiveRecord::Migration
  def self.up
    add_column :data_files, :template_name, :string, :default=> 'none'
    add_column :data_file_versions, :template_name, :string, :default=> 'none'
  end

  def self.down
    remove_column :data_files, :template_name
    remove_column :data_file_versions, :template_name
  end
end
