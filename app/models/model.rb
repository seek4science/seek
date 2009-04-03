require 'acts_as_resource'

class Model < ActiveRecord::Base

  acts_as_resource
  
  validates_presence_of :title
  
  # allow same titles, but only if these belong to different users
  validates_uniqueness_of :title, :scope => [ :contributor_id, :contributor_type ], :message => "error - you already have a SOP with such title."

  belongs_to :content_blob,
             :dependent => :destroy

  acts_as_solr(:fields=>[:description,:title,:original_filename]) if SOLR_ENABLED

  belongs_to :recommended_environment,:class_name=>"RecommendedModelEnvironment"
  
end
