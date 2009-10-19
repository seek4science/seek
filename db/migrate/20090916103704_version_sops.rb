class VersionSops < ActiveRecord::Migration  

  def self.up
    Sop.create_versioned_table
    def Sop.record_timestamps
      false
    end
    Sop.find(:all).each do |s|      
      s.save!      
    end

  end

  def self.down
    Sop.drop_versioned_table
  end
end
