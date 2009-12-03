require 'digest/md5'
require 'net/http'
require 'open-uri'


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
      resp = ""
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

  def md5sum
    if super.nil?
      other_changes=self.changed?
      calculate_md5
      #only save if there are no other changes - this is to avoid inadvertantly storing other potentially unwanted changes
      save unless other_changes
    end
    super
  end
  
  def calculate_md5
    unless self.data.nil?
      digest = Digest::MD5.new
      digest << self.data
      self.md5sum = digest.hexdigest
    end
  end
  
  #returns a hash of values to be used in send_data
  #:data, :filename, :content_type 
  def send_remote_data
    unless self.url.nil?
      filename = ""
      content_type = ""
      resp = ""
      uri = URI.parse(self.url)
      Net::HTTP.start(uri.host, uri.port) do |http|
        resp = http.get(uri.request_uri)
        #This is to get filenames from RESTful uris such as example.com/1/download
        if resp['content-disposition'] && resp['content-disposition'] =~ /attachment; filename=\".*\"/
          filename = resp['content-disposition'].split("filename=").last.gsub(/[\\\"]/,"")
        else
          filename = uri.path.split("/").last
        end
        content_type = resp.content_type
      end
      if resp.code == "200" #if all was okay, send the content we got 
        return {:data => resp.body, :filename => filename, :content_type => content_type}
      else #if we couldn't find it, send cached data
        return {:data => self.data}
      end
    else
      return nil
    end
  end
  
end
