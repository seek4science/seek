class AddUuidToSamples < ActiveRecord::Migration
  def self.up
    add_column :samples, :uuid, :string
  end

  def self.down
    remove_column :samples,:uuid
  end
end
