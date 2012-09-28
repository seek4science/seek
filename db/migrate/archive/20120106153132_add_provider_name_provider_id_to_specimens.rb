class AddProviderNameProviderIdToSpecimens < ActiveRecord::Migration
  def self.up
    add_column :specimens, :provider_id, :string
    add_column :specimens, :provider_name, :string
  end

  def self.down
    remove_column :specimens, :provider_id
    remove_column:specimens, :provider_name
  end
end
