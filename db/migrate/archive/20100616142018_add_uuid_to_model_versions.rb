class AddUuidToModelVersions < ActiveRecord::Migration
  def self.up
    add_column :model_versions, :uuid, :string
  end

  def self.down
    remove_column :model_versions,:uuid
  end
end
