require 'acts_as_resource'
require 'explicit_versioning'
require 'grouped_pagination'
require 'acts_as_uniquely_identifiable'

class Model < ActiveRecord::Base

  acts_as_resource
  acts_as_trashable
  
  has_many :favourites, 
    :as => :resource,
    :dependent => :destroy
  
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
  
  before_save :update_first_letter
  
  grouped_pagination  
  
  acts_as_uniquely_identifiable  
  
  explicit_versioning(:version_column => "version") do
    
    belongs_to :content_blob      
             
    belongs_to :organism
    belongs_to :recommended_environment,:class_name=>"RecommendedModelEnvironment"
    belongs_to :model_type
    belongs_to :model_format
    
    belongs_to :contributor, :polymorphic => true
    
    has_one :asset,
      :primary_key => "model_id",
      :foreign_key => "resource_id",
      :conditions => {:resource_type => "Model"}

    #FIXME: do this through a :has_one, :through=>:asset - though this currently working as primary key for :asset is ignored
    def project
      asset.project
    end
    
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
  
  def update_first_letter
    self.first_letter = strip_first_letter(title)
  end
  
end
