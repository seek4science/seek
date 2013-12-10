require 'acts_as_asset'
require 'explicit_versioning'
require 'title_trimmer'
require 'acts_as_versioned_resource'

class Sop < ActiveRecord::Base

  include Seek::Rdf::RdfGeneration

  #searchable must come before acts_as_asset is called
  searchable(:auto_index => false) do
    text :exp_conditions_search_fields,:assay_type_titles,:technology_type_titles, :other_creators
  end if Seek::Config.solr_enabled

  acts_as_asset
  acts_as_trashable

  scope :default_order, order("title")

  title_trimmer

  after_save :queue_background_reindexing if Seek::Config.solr_enabled

  validates_presence_of :title

  # allow same titles, but only if these belong to different users
  # validates_uniqueness_of :title, :scope => [ :contributor_id, :contributor_type ], :message => "error - you already have a SOP with such title."

  has_many :sample_assets,:dependent=>:destroy,:as => :asset
  has_many :samples, :through => :sample_assets

  #don't add a dependent=>:destroy, as the content_blob needs to remain to detect future duplicates
  has_one :content_blob, :as => :asset, :foreign_key => :asset_id ,:conditions => Proc.new{["content_blobs.asset_version =?", version]}

  has_many :experimental_conditions, :conditions =>  Proc.new{["experimental_conditions.sop_version =?", version]}

  has_many :sop_specimens
  has_many :specimens,:through=>:sop_specimens

  explicit_versioning(:version_column => "version") do
    acts_as_versioned_resource
    acts_as_favouritable
    has_one :content_blob,:primary_key => :sop_id,:foreign_key => :asset_id,:conditions => Proc.new{["content_blobs.asset_version =? AND content_blobs.asset_type =?", version,parent.class.name]}
    has_many :experimental_conditions, :primary_key => "sop_id", :foreign_key => "sop_id", :conditions =>  Proc.new{["experimental_conditions.sop_version =?",version]}
    
  end

  # get a list of SOPs with their original uploaders - for autocomplete fields
  # (authorization is done immediately to save from iterating through the collection again afterwards)
  #
  # Parameters:
  # - user - user that performs the action; this is required for authorization
  def self.get_all_as_json(user)
    all = Sop.all_authorized_for "view",user
    with_contributors = all.collect{ |d|
        contributor = d.contributor;
        { "id" => d.id,
          "title" => h(d.title),
          "contributor" => contributor.nil? ? "" : "by " + h(contributor.person.name),
          "type" => self.name
        }
    }
    return with_contributors.to_json
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

  #experimental_conditions, and related compound text that should be included in search
  def exp_conditions_search_fields
    flds = experimental_conditions.collect do |ec|
      [ec.measured_item.title,
       ec.substances.collect do |sub|
         #FIXME: this makes the assumption that the synonym.substance appears like a Compound
         sub = sub.substance if sub.is_a?(Synonym)
         [sub.title] |
             (sub.respond_to?(:synonyms) ? sub.synonyms.collect { |syn| syn.title } : []) |
             (sub.respond_to?(:mappings) ? sub.mappings.collect { |mapping| ["CHEBI:#{mapping.chebi_id}", mapping.chebi_id, mapping.sabiork_id.to_s, mapping.kegg_id] } : [])
       end
      ]
    end
    flds.flatten.uniq
  end
    
end
