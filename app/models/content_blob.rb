require 'digest/md5'
require 'net/http'
require 'open-uri'


class ContentBlob < ActiveRecord::Base
  validates_presence_of :data, :if => Proc.new { |blob| blob.url.blank? }  
  
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
  
  def calculate_md5
    #FIXME: only recalculate if the data has changed (should be able to do this with changes.keys.include?("data") or along those lines).
    unless self.data.nil?
      digest = Digest::MD5.new
      digest << self.data
      self.md5sum = digest.hexdigest
    end
  end  
  
end
