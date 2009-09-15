require 'acts_as_resource'

class Sop < ActiveRecord::Base
  acts_as_resource
  
  validates_presence_of :title
  
  # allow same titles, but only if these belong to different users
  validates_uniqueness_of :title, :scope => [ :contributor_id, :contributor_type ], :message => "error - you already have a SOP with such title."
  
  acts_as_solr(:fields=>[:description,:title,:original_filename,:organism_title]) if SOLR_ENABLED
  
  belongs_to :content_blob,
             :dependent => :destroy

  has_many :experimental_conditions
  has_and_belongs_to_many :assays  
  
  # get a list of SOPs with their original uploaders - for autocomplete fields
  # (authorization is done immediately to save from iterating through the collection again afterwards)
  #
  # Parameters:
  # - user - user that performs the action; this is required for authorization
  def self.get_all_as_json(user)
    all_sops = Sop.find(:all, :order => "ID asc")
    sops_with_contributors = all_sops.collect{ |s| 
        Authorization.is_authorized?("show", nil, s, user) ?
        (p = s.asset.contributor.person;
        { "id" => s.id,
          "title" => s.title,
          "contributor" => "by " +
                           (p.first_name.blank? ? (logger.error("\n----\nUNEXPECTED DATA: person id = #{p.id} doesn't have a first name\n----\n"); "(NO FIRST NAME)") : p.first_name) + " " +
                           (p.last_name.blank? ? (logger.error("\n----\nUNEXPECTED DATA: person id = #{p.id} doesn't have a last name\n----\n"); "(NO LAST NAME)") : p.last_name),
          "type" => self.name } ) :
        nil }
    
    sops_with_contributors.delete(nil)
    
    return sops_with_contributors.to_json
  end

  def organism_title
    organism.nil? ? "" : organism.title
  end
  
end
