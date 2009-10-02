class VersionDataFiles < ActiveRecord::Migration
  def self.up
    DataFile.create_versioned_table
    def DataFile.record_timestamps
      false
    end
    DataFile.find(:all).each do |d|      
      d.save
    end

  end

  def self.down
    DataFile.drop_versioned_table
  end
end
