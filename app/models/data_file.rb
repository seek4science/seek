require 'acts_as_resource'
require 'explicit_versioning'
require 'grouped_pagination'

class DataFile < ActiveRecord::Base

  acts_as_resource
  acts_as_trashable
  
  has_many :favourites, 
           :as => :resource, 
           :dependent => :destroy

  validates_presence_of :title

  # allow same titles, but only if these belong to different users
  # validates_uniqueness_of :title, :scope => [ :contributor_id, :contributor_type ], :message => "error - you already have a Data file with such title."

  belongs_to :content_blob #don't add a dependent=>:destroy, as the content_blob needs to remain to detect future duplicates

  acts_as_solr(:fields=>[:description,:title,:original_filename]) if SOLR_ENABLED  
  
  has_many :studied_factors, :conditions =>  'studied_factors.data_file_version = #{self.version}'
  
  before_save :update_first_letter
  
  grouped_pagination
  

  explicit_versioning(:version_column => "version") do
    
    belongs_to :content_blob
    
    belongs_to :contributor, :polymorphic => true
    
    has_many :studied_factors, :primary_key => "data_file_id", :foreign_key => "data_file_id", :conditions =>  'studied_factors.data_file_version = #{self.version}'
    
    has_one :asset,
            :primary_key => "data_file_id",
            :foreign_key => "resource_id",
            :conditions => {:resource_type => "DataFile"}
            
    #FIXME: do this through a :has_one, :through=>:asset - though this currently working as primary key for :asset is ignored
    def project
      asset.project
    end
    
    def relationship_type(assay)
      AssayAsset.find_by_assay_id_and_asset_id(assay,self.asset).relationship_type  
    end
  end

  def assays
    AssayAsset.find(:all,:conditions=>["asset_id = ?",self.asset.id]).collect{|a| a.assay}
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
        Authorization.is_authorized?("show", nil, d, user) ?
        (contributor = d.contributor;
        { "id" => d.id,
          "title" => d.title,
          "contributor" => contributor.nil? ? "" : "by " + contributor.person.name,
          "type" => self.name } ) :
        nil }

    datafiles_with_contributors.delete(nil)

    return datafiles_with_contributors.to_json
  end
  
  def update_first_letter
    self.first_letter = strip_first_letter(title)
  end

  def relationship_type(assay)
    AssayAsset.find_by_assay_id_and_asset_id(assay,self.asset).relationship_type  
  end
end
