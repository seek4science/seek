class VersionSops < ActiveRecord::Migration
  def self.up
    Sop.create_versioned_table
  end

  def self.down
    Sop.drop_versioned_table
  end
end
