require 'acts_as_resource'

class Sop < ActiveRecord::Base
  acts_as_resource
  
  validates_presence_of :title
  
  # TODO add indexing by SOLR
  #acts_as_solr(:fields => [:title, :local_name, :body, :content_type, :uploader],
  #             :include => [ :comments ]) if SOLR_ENABLE
  
  belongs_to :content_blob,
             :dependent => :destroy
  
  # TODO
  # add all required validations here
  
end
