require 'digest/md5'
require 'net/http'


class ContentBlob < ActiveRecord::Base
  validates_presence_of :data, :if => Proc.new { |blob| blob.url.blank? }  
  
  before_save :calculate_md5
  
  #Caches the data from the url into the database, and returns
  # information about the file, such as original_filename and content_type
  # for use in the associated model
  def cache_remote_content
    unless self.url.nil?
      original_filename = ""
      content_type = ""
      uri = URI.parse(self.url)
      Net::HTTP.start(uri.host, uri.port) do |http|
        resp = http.get(uri.request_uri)
        self.data = resp.body
        #This is to get filenames from RESTful uris such as example.com/1/download
        if resp['content-disposition'] && resp['content-disposition'] =~ /attachment; filename=\".*\"/
          original_filename = resp['content-disposition'].split("filename=").last.gsub(/[\\\"]/,"")
        else
          original_filename = uri.path.split("/").last
        end
        content_type = resp.content_type
      end
      calculate_md5
      self.save!
      return original_filename, content_type
    end
  end
  
  def calculate_md5
    unless self.data.nil?
      d = Digest::MD5.new    
      d << self.data
      self.md5sum = d.hexdigest
    end
  end
  
end
