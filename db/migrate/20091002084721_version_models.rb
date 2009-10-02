class VersionModels < ActiveRecord::Migration
  def self.up
    Model.create_versioned_table
    def Model.record_timestamps
      false
    end
    Model.find(:all).each do |m|      
      m.save
    end

  end

  def self.down
    Model.drop_versioned_table
  end
end
