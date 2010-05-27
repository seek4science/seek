require 'digest/md5'
require 'net/http'
require 'open-uri'
require 'acts_as_uniquely_identifiable'
require 'tmpdir'

class ContentBlob < ActiveRecord::Base
  
  DATA_STORAGE_PATH = "filestore/content_blobs/"
  
  attr_writer :data
  
  #validates_presence_of :data, :if => Proc.new { |blob| blob.url.blank? }  
  
  acts_as_uniquely_identifiable
  before_save :dump_data_to_file
  
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
      path = "#{Dir::tmpdir}/seek_content_blobs/"
    else
      path = "#{RAILS_ROOT}/#{DATA_STORAGE_PATH}"
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
  
end
