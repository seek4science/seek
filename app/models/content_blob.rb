require 'digest/md5'
require 'net/http'
require 'open-uri'
require 'tmpdir'

class ContentBlob < ActiveRecord::Base
  
  DATA_STORAGE_PATH = "filestore/content_blobs/"
  
  #the actual data value stored in memory. If this could be large, then using :tmp_io_object is preferred
  attr_writer :data
  
  #this is used as an alternative to passing the data contents directly (in memory).
  #it is not stored in the database, but when the content_blob is saved is save, the IO object is read and stored in the correct location.
  #if the file doesn't exist an error occurs
  attr_writer :tmp_io_object
  
  acts_as_uniquely_identifiable
  
  #this action saves the contents of @data or the contents contained within the @tmp_io_object to the storage file.
  #an Exception is raised if both are defined
  before_save :dump_data_to_file
  
  before_save :calculate_md5

  has_many :worksheets, :dependent => :destroy

  def spreadsheet_annotations
    worksheets.collect {|w| w.cell_ranges.collect {|c| c.annotations}}.flatten
  end

  #returns the size of the file in bytes, or nil if the file doesn't exist
  def filesize
    if file_exists?
      File.size(filepath)
    else
      nil
    end
  end
  
  def md5sum
    if super.nil?
      other_changes=self.changed?
      calculate_md5
      #only save if there are no other changes - this is to avoid inadvertantly storing other potentially unwanted changes
      save unless other_changes
    end
    super
  end

  def cache_key
    "#{super}-#{md5sum}"
  end
  
  #returns an IO Object to the data content, or nil if the data file doesn't exist. 
  # In the case that there is a URL defined, but no local copy, the IO Object is still nil.
  def data_io_object
    return @tmp_io_object unless @tmp_io_object.nil?
    return StringIO.new(@data) unless @data.nil? 
    return File.open(filepath,"rb") if file_exists?
    return StringIO.new(data_old) unless data_old.nil?
    return nil
  end
  
  def calculate_md5
    #FIXME: only recalculate if the data has changed (should be able to do this with changes.keys.include?("data") or along those lines).
    if file_exists?
      digest = Digest::MD5.new
      digest.file(filepath)
      self.md5sum = digest.hexdigest
    end
  end        
  
  def file_exists?
    File.exist?(filepath)
  end
  
  def filepath uuid_to_use=nil
    uuid_to_use ||= uuid
    if RAILS_ENV == "test"
      path = "#{Dir::tmpdir}/seek_content_blobs"
    else
      path = "#{RAILS_ROOT}/#{DATA_STORAGE_PATH}/#{RAILS_ENV}"
    end
    FileUtils.mkdir_p(path)
    return "#{path}/#{uuid_to_use}.dat"
  end
  
  def dump_data_to_file        
    raise Exception.new("You cannot define both :data content and a :tmp_io_object") unless @data.nil? || @tmp_io_object.nil?
    check_uuid
    unless @tmp_io_object.nil?
      dump_tmp_io_object_to_file
    else
      dump_data_object_to_file
    end    
  end
  
  private
  
  def dump_data_object_to_file
    data_to_save = @data
    data_to_save ||= self.data_old
    
    if !data_to_save.nil?
      File.open(filepath,"w+") do |f|      
        f.write(data_to_save)    
      end
    end
  end
  
  def dump_tmp_io_object_to_file
    raise Exception.new("You cannot define both :data content and a :tmp_io_object") unless @data.nil? || @tmp_io_object.nil?
    t1 = Time.now
    unless @tmp_io_object.nil?
      begin
        logger.info "Moving #{@tmp_io_object.path} to #{filepath}"
        @tmp_io_object.flush if @tmp_io_object.respond_to? :flush
        FileUtils.mv @tmp_io_object.path, filepath
        @tmp_io_object = nil
      rescue Exception => e
        logger.info "Falling back to ruby copy because of: #{e.message}"
        @tmp_io_object.rewind

        File.open(filepath, "w+") do |f|
          buffer=""
          while @tmp_io_object.read(16384, buffer)
            f << buffer
          end
        end
        @tmp_io_object.rewind
        @tmp_io_object=nil
      end
    end
    logger.info "TIME: dump_tmp_io_object_to_file took #{Time.now - t1}"
  end
  
end
