require 'digest/md5'

class ContentBlob < ActiveRecord::Base
  validates_presence_of :data
  
  before_save :calculate_md5
  
  def calculate_md5
    d = Digest::MD5.new    
    d << self.data
    self.md5sum = d.hexdigest
  end  
  
end
