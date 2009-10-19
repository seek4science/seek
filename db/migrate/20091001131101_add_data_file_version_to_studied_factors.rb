class AddDataFileVersionToStudiedFactors < ActiveRecord::Migration

  def self.up
    add_column :studied_factors, :data_file_version, :integer
  end

  def self.down
    remove_column :studied_factors, :data_file_version
  end

end
