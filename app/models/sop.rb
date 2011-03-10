require 'acts_as_asset'
require 'explicit_versioning'
require 'grouped_pagination'
require 'title_trimmer'
require 'acts_as_versioned_resource'

class Sop < ActiveRecord::Base

  acts_as_asset
  acts_as_trashable
  
  title_trimmer

  validates_presence_of :title

  # allow same titles, but only if these belong to different users
  # validates_uniqueness_of :title, :scope => [ :contributor_id, :contributor_type ], :message => "error - you already have a SOP with such title."

  acts_as_solr(:fields=>[:description, :title, :original_filename]) if Seek::ApplicationConfiguration.solr_enabled

  belongs_to :content_blob #don't add a dependent=>:destroy, as the content_blob needs to remain to detect future duplicates
               
  has_one :investigation,:through=>:study
             
  has_many :experimental_conditions, :conditions =>  'experimental_conditions.sop_version = #{self.version}'

  acts_as_uniquely_identifiable  

  explicit_versioning(:version_column => "version") do
    
    acts_as_versioned_resource
    
    belongs_to :content_blob
    
    has_many :experimental_conditions, :primary_key => "sop_id", :foreign_key => "sop_id", :conditions =>  'experimental_conditions.sop_version = #{self.version}'
    
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


  def use_mime_type_for_avatar?
    true
  end

  #defines that this is a user_creatable object type, and appears in the "New Object" gadget
  def self.user_creatable?
    true
  end
    
end
