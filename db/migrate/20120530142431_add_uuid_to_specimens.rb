class AddUuidToSpecimens < ActiveRecord::Migration
  def self.up
    add_column :specimens, :uuid, :string
  end

  def self.down
    remove_column :specimens,:uuid
  end
end
