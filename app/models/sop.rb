require 'acts_as_resource'

class Sop < ActiveRecord::Base
  acts_as_resource
  
  validates_presence_of :title
  
  acts_as_solr(:fields=>[:description,:title,:original_filename]) if SOLR_ENABLED
  
  belongs_to :content_blob,
             :dependent => :destroy
  
  # TODO
  # add all required validations here
  
end
