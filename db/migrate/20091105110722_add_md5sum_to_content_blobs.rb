class AddMd5sumToContentBlobs < ActiveRecord::Migration
  
  def self.up
    add_column :content_blobs, :md5sum, :string  
    
    #Re-save all blobs to calculate md5 checksum on them
    ContentBlob.all.each do |c|
      c.save     
    end
    
  end

  def self.down
    remove_column :content_blobs, :md5sum
  end
  
end
