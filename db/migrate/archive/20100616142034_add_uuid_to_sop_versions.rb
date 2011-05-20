class AddUuidToSopVersions < ActiveRecord::Migration
  def self.up
    add_column :sop_versions, :uuid, :string
  end

  def self.down
    remove_column :sop_versions,:uuid
  end
end
