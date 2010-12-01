require 'digest/md5'
require 'net/http'
require 'open-uri'
require 'acts_as_uniquely_identifiable'
require 'tmpdir'

class ContentBlob < ActiveRecord::Base
  
  DATA_STORAGE_PATH = "filestore/content_blobs/"
  
  #the actual data value stored in memeory. If this could be large, then using :tmp_io_object is preferred
  attr_writer :data
  
  #this is used as an alternative to passing the data contents directly (in memory).
  #it is not stored in the database, but when the content_blob is saved is save, the IO object is read and stored in the correct location.
  #if the file doesn't exist an error occurs
  attr_writer :tmp_io_object
      
  acts_as_uniquely_identifiable
  
  #this action saves the contents of @data to the storage file
  before_save :dump_data_to_file
  
  #stores the contents contained within the @tmp_io_object to the storage file
  before_save :dumo_tmp_io_object_to_file
    
  before_save :calculate_md5
  
  def md5sum
    if super.nil?
      other_changes=self.changed?
      calculate_md5
      #only save if there are no other changes - this is to avoid inadvertantly storing other potentially unwanted changes
      save unless other_changes
    end
    super
  end
  
  def data    
    return @data if @data
    return File.open(filepath,"rb").read if file_exists?   
    unless self.data_old.blank?
      dump_data_to_file
      return self.data_old
    end     
    return nil
  end
  
  def calculate_md5
    #FIXME: only recalculate if the data has changed (should be able to do this with changes.keys.include?("data") or along those lines).
    unless self.data.nil?
      digest = Digest::MD5.new
      digest << self.data
      self.md5sum = digest.hexdigest
    end
  end        
  
  def file_exists?
    File.exist?(filepath)
  end
  
  def filepath
    if RAILS_ENV == "test"
      path = "#{Dir::tmpdir}/seek_content_blobs"
    else
      path = "#{RAILS_ROOT}/#{DATA_STORAGE_PATH}/#{RAILS_ENV}"
    end
    FileUtils.mkdir_p(path)
    return "#{path}/#{uuid}.dat"
  end
  
  def dump_data_to_file        
    data_to_save = @data
    data_to_save ||= self.data_old
    
    if !data_to_save.nil?
      File.open(filepath,"w+") do |f|      
        f.write(data_to_save)    
      end
    end
  end
  
  def dumo_tmp_io_object_to_file
    unless @tmp_io_object.nil?
      @tmp_io_object.rewind
      File.open(filepath,"w+") do |f|      
        @tmp_io_object.each_byte do |byte|
          f << byte.chr
        end        
      end
    end
  end
  
end
