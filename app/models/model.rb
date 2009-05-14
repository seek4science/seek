require 'acts_as_resource'

class Model < ActiveRecord::Base

  acts_as_resource
  
  validates_presence_of :title
  
  # allow same titles, but only if these belong to different users
  validates_uniqueness_of :title, :scope => [ :contributor_id, :contributor_type ], :message => "error - you already have a SOP with such title."

  belongs_to :content_blob,
             :dependent => :destroy

  belongs_to :organism

  acts_as_solr(:fields=>[:description,:title,:original_filename]) if SOLR_ENABLED

  belongs_to :recommended_environment,:class_name=>"RecommendedModelEnvironment"

  has_many :created_datas

  # get a list of Models with their original uploaders - for autocomplete fields
  # (authorization is done immediately to save from iterating through the collection again afterwards)
  #
  # Parameters:
  # - user - user that performs the action; this is required for authorization
  def self.get_all_as_json(user)
    all_models = Model.find(:all, :order => "ID asc")
    models_with_contributors = all_models.collect{ |m|
        Authorization.is_authorized?("show", nil, m, user) ?
        (p = m.asset.contributor.person;
        { "id" => m.id,
          "title" => m.title,
          "contributor" => "by " +
                           (p.first_name.blank? ? (logger.error("\n----\nUNEXPECTED DATA: person id = #{p.id} doesn't have a first name\n----\n"); "(NO FIRST NAME)") : p.first_name) + " " +
                           (p.last_name.blank? ? (logger.error("\n----\nUNEXPECTED DATA: person id = #{p.id} doesn't have a last name\n----\n"); "(NO LAST NAME)") : p.last_name),
          "type" => self.name } ) :
        nil }

    models_with_contributors.delete(nil)

    return models_with_contributors.to_json
  end
  
end
