class AddExternalFlagToSavedSearch < ActiveRecord::Migration
  def self.up
    add_column :saved_searches, :include_external_search, :boolean,:default=>false
  end

  def self.down
    remove_column :saved_searches, :include_external_search
  end
end
