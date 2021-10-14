class Organism < ApplicationRecord
  include Seek::Rdf::RdfGeneration
  include Seek::Search::BackgroundReindexing
  include Seek::BioSchema::Support

  acts_as_favouritable
  grouped_pagination
  acts_as_uniquely_identifiable

  linked_to_bioportal apikey: Seek::Config.bioportal_api_key

  has_many :assay_organisms, inverse_of: :organism
  has_many :models
  has_many :model_publications, through: :models, source: :publications
  has_many :assays, through: :assay_organisms, inverse_of: :organisms
  has_many :assay_publications, through: :assays, source: :publications
  has_many :strains, dependent: :destroy
  has_many :samples, through: :strains

  has_and_belongs_to_many :projects
  has_many :programmes, through: :projects
  
  before_validation :convert_concept_uri

  validates_presence_of :title
  validates :concept_uri, url: { allow_nil: true, allow_blank: true }
  validates :concept_uri, ncbi_concept_uri: true, allow_blank: true

  validate do |organism|
    unless organism.bioportal_concept.nil? || organism.bioportal_concept.valid?
      organism.bioportal_concept.errors.each do |attr, msg|
        errors.add(attr, msg)
      end
    end
  end

  if Seek::Config.solr_enabled
    searchable(auto_index: false) do
      text :title
      text :searchable_terms
      text :ncbi_id
    end
  end

  # Returns the columns to be shown on the table view for the resource
  def columns_default
    super
  end
  def columns_allowed
    columns_default + ['title']
  end

  def can_delete?(user = User.current_user)
    !user.nil? && user.is_admin_or_project_administrator? && models.empty? && assays.empty? && projects.empty?
  end

  def can_manage?(_user = User.current_user)
    User.admin_logged_in?
  end

  def searchable_terms
    terms = [title]
    if concept
      terms |= concept[:synonyms].collect { |s| s.delete('\""') } if concept[:synonyms]
      terms |= concept[:definitions].collect { |s| s.delete('\""') } if concept[:definitions]
    end
    terms
  end

  def self.can_create?
    User.admin_or_project_administrator_logged_in? || User.activated_programme_administrator_logged_in?
  end

  # overides that from the bioportal gem, to always make sure it is based on http://purl.bioontology.org/ontology/NCBITAXON/
  def ncbi_uri
    return nil if ncbi_id.nil?
    "http://purl.bioontology.org/ontology/NCBITAXON/#{ncbi_id}"
  end

  def related_publications
    Publication.where(id: related_publication_ids)
  end

  def related_publication_ids
    assay_publication_ids | model_publication_ids
  end

  # converts the concept uri into a common form of http://purl.bioontology.org/ontology/NCBITAXON/<Number> if:
  #   - it is just a number
  #   - of the form NCBITaxon:<Number>
  #   - a identifiers.org URI
  # if it doesn't match these rules it is left as it is
  def convert_concept_uri
    concept_uri&.strip!
    case concept_uri
    when /\A\d+\Z/
      self.concept_uri = "http://purl.bioontology.org/ontology/NCBITAXON/#{concept_uri}"
    when /\ANCBITaxon:\d+\Z/i
      self.concept_uri = "http://purl.bioontology.org/ontology/NCBITAXON/#{concept_uri.gsub(/NCBITaxon:/i, '')}"
    when /\Ahttps?:\/\/identifiers\.org\/taxonomy\/\d+\Z/i
      self.concept_uri = "http://purl.bioontology.org/ontology/NCBITAXON/#{concept_uri.gsub(/https?:\/\/identifiers\.org\/taxonomy\//i, '')}"
    end
  end
end
