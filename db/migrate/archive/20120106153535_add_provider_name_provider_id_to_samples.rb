class AddProviderNameProviderIdToSamples < ActiveRecord::Migration
  def self.up
    add_column :samples, :provider_id, :string
    add_column :samples, :provider_name, :string
  end

  def self.down
    remove_column :samples, :provider_id
    remove_column:samples, :provider_name
  end
end
