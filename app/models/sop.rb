require 'acts_as_resource'
require 'explicit_versioning'
require 'grouped_pagination'

class Sop < ActiveRecord::Base

  acts_as_resource
  acts_as_trashable
  
  has_many :favourites, 
    :as => :resource,
    :dependent => :destroy

  validates_presence_of :title

  # allow same titles, but only if these belong to different users
  # validates_uniqueness_of :title, :scope => [ :contributor_id, :contributor_type ], :message => "error - you already have a SOP with such title."

  acts_as_solr(:fields=>[:description, :title, :original_filename]) if SOLR_ENABLED

  belongs_to :content_blob #don't add a dependent=>:destroy, as the content_blob needs to remain to detect future duplicates
               
  has_one :investigation,:through=>:study
             
  has_many :experimental_conditions, :conditions =>  'experimental_conditions.sop_version = #{self.version}'
  
  before_save :update_first_letter
  
  grouped_pagination
  

  explicit_versioning(:version_column => "version") do
    
    belongs_to :content_blob
    
    belongs_to :contributor, :polymorphic => true
    
    has_many :experimental_conditions, :primary_key => "sop_id", :foreign_key => "sop_id", :conditions =>  'experimental_conditions.sop_version = #{self.version}'
    
    has_one :asset,
      :primary_key => "sop_id",
      :foreign_key => "resource_id",
      :conditions => {:resource_type => "Sop"}
            
    #FIXME: do this through a :has_one, :through=>:asset - though this currently working as primary key for :asset is ignored
    def project
      asset.project
    end
  end

  def assays
    AssayAsset.find(:all,:conditions=>["asset_id = ?",self.asset.id]).collect{|a| a.assay}
  end

  def studies
    assays.collect{|a| a.study}.uniq
  end

  # get a list of SOPs with their original uploaders - for autocomplete fields
  # (authorization is done immediately to save from iterating through the collection again afterwards)
  #
  # Parameters:
  # - user - user that performs the action; this is required for authorization
  def self.get_all_as_json(user)
    all_sops = Sop.find(:all, :order => "ID asc")
    sops_with_contributors = all_sops.collect{ |s|
      Authorization.is_authorized?("show", nil, s, user) ?
        (contributor = s.contributor;
        { "id" => s.id,
          "title" => s.title,
          "contributor" => contributor.nil? ? "" : "by " + contributor.person.name,
          "type" => self.name } ) :
        nil }

    sops_with_contributors.delete(nil)

    return sops_with_contributors.to_json
  end

  def organism_title
    organism.nil? ? "" : organism.title
  end 
  
  def update_first_letter
    self.first_letter = strip_first_letter(title)
  end
end
