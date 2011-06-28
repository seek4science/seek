require 'acts_as_asset'
require 'acts_as_versioned_resource'
require 'explicit_versioning'
require 'grouped_pagination'
require 'title_trimmer'

class DataFile < ActiveRecord::Base

  acts_as_asset
  acts_as_trashable

  title_trimmer

  if Seek::Config.events_enabled
    has_and_belongs_to_many :events
  else
    def events
      []
    end

    def event_ids
      []
    end

    def event_ids= events_ids
      
    end
  end

  validates_presence_of :title

  # allow same titles, but only if these belong to different users
  # validates_uniqueness_of :title, :scope => [ :contributor_id, :contributor_type ], :message => "error - you already have a Data file with such title."

  belongs_to :content_blob #don't add a dependent=>:destroy, as the content_blob needs to remain to detect future duplicates

  acts_as_solr(:fields=>[:description,:title,:original_filename,:tag_counts]) if Seek::Config.solr_enabled

  has_many :studied_factors, :conditions =>  'studied_factors.data_file_version = #{self.version}'

  acts_as_uniquely_identifiable


  explicit_versioning(:version_column => "version") do
    acts_as_versioned_resource
    
    belongs_to :content_blob
    
    has_many :studied_factors, :primary_key => "data_file_id", :foreign_key => "data_file_id", :conditions =>  'studied_factors.data_file_version = #{self.version}'
    
    def relationship_type(assay)
      parent.relationship_type(assay)
    end
  end

  def studies
    assays.collect{|a| a.study}.uniq
  end

  # get a list of DataFiles with their original uploaders - for autocomplete fields
  # (authorization is done immediately to save from iterating through the collection again afterwards)
  #
  # Parameters:
  # - user - user that performs the action; this is required for authorization
  def self.get_all_as_json(user)
    all_datafiles = DataFile.find(:all, :order => "ID asc")
    datafiles_with_contributors = all_datafiles.collect{ |d|
        d.can_view?(user) ?
        (contributor = d.contributor;
        { "id" => d.id,
          "title" => d.title,
          "contributor" => contributor.nil? ? "" : "by " + contributor.person.name,
          "type" => self.name } ) :
        nil }

    datafiles_with_contributors.delete(nil)

    return datafiles_with_contributors.to_json
  end

  def self.spreadsheets
    
  end
  

  def relationship_type(assay)
    #FIXME: don't like this hardwiring to assay within data file, needs abstracting
    assay_assets.find_by_assay_id(assay.id).relationship_type  
  end

  def use_mime_type_for_avatar?
    true
  end

  #defines that this is a user_creatable object type, and appears in the "New Object" gadget
  def self.user_creatable?
    true
  end
  
end
