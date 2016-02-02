
require 'explicit_versioning'
require 'title_trimmer'
require 'acts_as_versioned_resource'

class Sop < ActiveRecord::Base

  include Seek::Rdf::RdfGeneration

  #searchable must come before acts_as_asset is called
  searchable(:auto_index => false) do
    text :exp_conditions_search_fields
  end if Seek::Config.solr_enabled

  acts_as_asset

  include Seek::Dois::DoiGeneration

  scope :default_order, order("title")

  #don't add a dependent=>:destroy, as the content_blob needs to remain to detect future duplicates
  has_one :content_blob, :as => :asset, :foreign_key => :asset_id ,:conditions => Proc.new{["content_blobs.asset_version =?", version]}

  has_many :experimental_conditions, :conditions =>  Proc.new{["experimental_conditions.sop_version =?", version]}

  #DEPRECATED
  has_many :sop_deprecated_specimens, :dependent => :destroy
  has_many :deprecated_specimens,:through=>:sop_deprecated_specimens
  has_many :deprecated_sample_assets,:dependent=>:destroy,:as => :asset
  has_many :deprecated_samples, :through => :sample_assets

  explicit_versioning(:version_column => "version") do
    acts_as_versioned_resource
    acts_as_favouritable
    has_one :content_blob,:primary_key => :sop_id,:foreign_key => :asset_id,:conditions => Proc.new{["content_blobs.asset_version =? AND content_blobs.asset_type =?", version,parent.class.name]}
    has_many :experimental_conditions, :primary_key => "sop_id", :foreign_key => "sop_id", :conditions =>  Proc.new{["experimental_conditions.sop_version =?",version]}
    
  end

  def organism_title
    organism.nil? ? "" : organism.title
  end

  def use_mime_type_for_avatar?
    true
  end

  #defines that this is a user_creatable object type, and appears in the "New Object" gadget
  def self.user_creatable?
    true
  end
    
end
