require 'acts_as_asset'
require 'acts_as_versioned_resource'
require 'explicit_versioning'
require 'grouped_pagination'
require 'acts_as_uniquely_identifiable'
require 'title_trimmer'

class Model < ActiveRecord::Base

  title_trimmer
  
  acts_as_asset
  acts_as_trashable  
  
  validates_presence_of :title
  
  # allow same titles, but only if these belong to different users
  # validates_uniqueness_of :title, :scope => [ :contributor_id, :contributor_type ], :message => "error - you already have a Model with such title."

  belongs_to :content_blob #don't add a dependent=>:destroy, as the content_blob needs to remain to detect future duplicates    

  belongs_to :organism
  belongs_to :recommended_environment,:class_name=>"RecommendedModelEnvironment"
  belongs_to :model_type
  belongs_to :model_format
  
  acts_as_solr(:fields=>[:description,:title,:original_filename,:organism_name]) if SOLR_ENABLED

  has_many :created_datas    

  
  acts_as_uniquely_identifiable
  
  explicit_versioning(:version_column => "version") do
    acts_as_versioned_resource
    
    belongs_to :content_blob             
    belongs_to :organism
    belongs_to :recommended_environment,:class_name=>"RecommendedModelEnvironment"
    belongs_to :model_type
    belongs_to :model_format
  end

  def studies
    assays.collect{|a| a.study}.uniq
  end  

  # get a list of Models with their original uploaders - for autocomplete fields
  # (authorization is done immediately to save from iterating through the collection again afterwards)
  #
  # Parameters:
  # - user - user that performs the action; this is required for authorization
  def self.get_all_as_json(user)
    all_models = Model.find(:all, :order => "ID asc")

    models_with_contributors = all_models.collect{ |m|
      Authorization.is_authorized?("show", nil, m, user) ?
        (contributor = m.contributor;
        { "id" => m.id,
          "title" => m.title,
          "contributor" => contributor.nil? ? "" : "by " + contributor.person.name,
          "type" => self.name } ) :
        nil }

    models_with_contributors.delete(nil)

    return models_with_contributors.to_json
  end

  def organism_name
    organism.title unless organism.nil?
  end

  #defines that this is a user_creatable object, and appears in the "New Object" gadget
  def self.user_creatable?
    true
  end
  
end
