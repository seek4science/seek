
require 'acts_as_versioned_resource'
require 'explicit_versioning'
require 'title_trimmer'

class Model < ActiveRecord::Base

  include Seek::Rdf::RdfGeneration

  title_trimmer

  #searchable must come before acts_as_asset call
  searchable(:auto_index=>false) do
    text :organism_terms,:model_contents_for_search
    text :model_format do
      model_format.try(:title)
    end
    text :model_type do
      model_type.try(:title)
    end
    text :recommended_environment do
      recommended_environment.try(:title)
    end
  end if Seek::Config.solr_enabled

  acts_as_asset

  include Seek::Dois::DoiGeneration

  scope :default_order, order("title")

  include Seek::Models::ModelExtraction

  validates_presence_of :title

  before_save :check_for_sbml_format
  
  # allow same titles, but only if these belong to different users
  # validates_uniqueness_of :title, :scope => [ :contributor_id, :contributor_type ], :message => "error - you already have a Model with such title."
  has_many :sample_assets,:dependent=>:destroy,:as => :asset
  has_many :samples, :through => :sample_assets

  #FIXME: model_images seems to be to keep persistence of old images, wheras model_image is just the current_image
  has_many :model_images
  belongs_to :model_image

  has_many :content_blobs, :as => :asset, :foreign_key => :asset_id,:conditions => Proc.new{["content_blobs.asset_version =?", version]}

  belongs_to :organism
  belongs_to :recommended_environment,:class_name=>"RecommendedModelEnvironment"
  belongs_to :model_type
  belongs_to :model_format


  explicit_versioning(:version_column => "version") do
    include Seek::Models::ModelExtraction
    acts_as_versioned_resource
    acts_as_favouritable

    belongs_to :model_image
    belongs_to :organism
    belongs_to :recommended_environment,:class_name=>"RecommendedModelEnvironment"
    belongs_to :model_type
    belongs_to :model_format

    def model_format
      if read_attribute(:model_format_id).nil? && contains_sbml?
        ModelFormat.sbml.first
      else
        super
      end
    end

    def content_blobs
      ContentBlob.where(["asset_id =? and asset_type =? and asset_version =?", self.parent.id, self.parent.class.name, self.version])
    end

  end

  def organism_terms
    if organism
      organism.searchable_terms
    else
      []
    end
  end

  #defines that this is a user_creatable object, and appears in the "New Object" gadget
  def self.user_creatable?
    Seek::Config.models_enabled
  end

  #a simple container for handling the matching results returned from #matching_data_files
  class DataFileMatchResult < Struct.new(:search_terms,:score,:primary_key);end

  #return a an array of DataFileMatchResult where the data file id is the key, and the matching terms/values are the values
  def matching_data_files params_only=false
    
    results = {}

    if Seek::Config.solr_enabled && is_jws_supported?
      search_terms = parameters_and_values.keys
      unless params_only
        search_terms = search_terms | species | searchable_tags | organism_terms
      end
      #make the array uniq! case-insensistive whilst mainting the original case
      dc = []
      search_terms = search_terms.inject([]) do |r,v|
        unless dc.include?(v.downcase)
          r << v
          dc << v.downcase
        end
        r
      end

      fields = [:fs_search_fields, :content_blob,:spreadsheet_annotation_search_fields, :searchable_tags]

      search_terms.each do |key|
        key = Seek::Search::SearchTermFilter.filter(key)
        unless key.blank?
          DataFile.search do |query|
            query.keywords key, :fields=>fields
          end.hits.each do |hit|
            unless hit.score.nil?
              results[hit.primary_key]||=DataFileMatchResult.new([],0,hit.primary_key)
              results[hit.primary_key].search_terms << key
              results[hit.primary_key].score += (0.75 + hit.score)
            end
          end
        end
      end
    end

    results.values.sort_by{|a| -a.score}
  end

  def model_format
    if read_attribute(:model_format_id).nil? && contains_sbml?
      ModelFormat.sbml.first
    else
      super
    end
  end

  private

  def check_for_sbml_format
    self.model_format = self.model_format
  end
  
end
