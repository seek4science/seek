class HumanDisease < ApplicationRecord
  include Seek::Rdf::RdfGeneration
  include Seek::Search::BackgroundReindexing
  include Seek::BioSchema::Support

  acts_as_favouritable
  grouped_pagination
  acts_as_uniquely_identifiable

  linked_to_bioportal apikey: Seek::Config.bioportal_api_key

  has_many :assay_human_diseases, inverse_of: :human_disease
  has_many :models
  has_many :model_publications, through: :models, source: :publications
  has_many :assays, through: :assay_human_diseases, inverse_of: :human_diseases
  has_many :assay_publications, through: :assays, source: :publications

  has_and_belongs_to_many :projects
  has_and_belongs_to_many :publications

  has_many :human_disease_parents, foreign_key: 'human_disease_id', class_name: 'HumanDiseaseParent'
  has_many :parents, through: :human_disease_parents, source: :parent, dependent: :destroy

  has_many :human_disease_children, foreign_key: 'parent_id', class_name: 'HumanDiseaseParent'
  has_many :children, through: :human_disease_children, source: :child, dependent: :destroy

  before_validation :convert_concept_uri

  validates_presence_of :title
  validates :concept_uri, url: { allow_nil: true, allow_blank: true }

  before_save do |human_disease|
    unless human_disease.concept_uri.nil? or human_disease.concept_uri.empty?
      human_disease.doid_id = human_disease.concept_uri.gsub(/^.*?\/obo\//i, '')
    end

    unless bioportal_base_rest_url.empty? or human_disease.concept_uri.nil? or human_disease.concept_uri.empty? or Seek::Config::bioportal_api_key.empty?
      parents = []
      begin
        get_json(bioportal_base_rest_url + "/ontologies/DOID/classes/" + ERB::Util.url_encode(human_disease.concept_uri) + '/parents').each do |parent|
          parent_obj = HumanDisease.find_by doid_id: parent['@id'].gsub(/^.*?\/obo\//i, '')
          unless parent_obj
            parent_obj = HumanDisease.new(concept_uri: parent['@id'], title: parent['prefLabel'], ontology_id: 'DOID')
            parent_obj.save
          end
          parents.push parent_obj
        end
      rescue StandardError => e
        logger.warn e.message
      end
      human_disease.parents = parents
    end
  end

  validate do |human_disease|
    unless human_disease.bioportal_concept.nil? || human_disease.bioportal_concept.valid?
      human_disease.bioportal_concept.errors.each do |attr, msg|
        errors.add(attr, msg)
      end
    end
  end

  if Seek::Config.solr_enabled
    searchable(auto_index: false) do
      text :title
      text :searchable_terms
      text :doid_id
    end
  end

  def can_delete?(user = User.current_user)
    !user.nil? && user.is_admin_or_project_administrator? && models.empty? && assays.empty? && projects.empty? && publications.empty?
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

  # overides that from the bioportal gem, to always make sure it is based on http://purl.bioontology.org/obo/
  def doid_uri
    return nil if doid_id.nil?
    "http://purl.bioontology.org/obo/DOID_#{doid_id}"
  end

  # converts the concept uri into a common form of http://purl.bioontology.org/obo/DOID_<Number> if:
  #   - it is just a number
  #   - of the form DOID_<Number>
  #   - a identifiers.org URI
  # if it doesn't match these rules it is left as it is
  def convert_concept_uri
    concept_uri&.strip!
    case concept_uri
    when /\A\d+\Z/
      self.concept_uri = "http://purl.bioontology.org/obo/DOID_#{concept_uri}"
    when /\ADOID_\d+\Z/i
      self.concept_uri = "http://purl.bioontology.org/obo/#{concept_uri}"
    end
  end

  def to_node(selected = nil, ignore_count = false)
    ids = projects.pluck(:id).map { |x| 'proj_' + x.to_s } +
      assays.pluck(:id).map { |x| 'ass_' + x.to_s } +
      models.pluck(:id).map { |x| 'mod_' + x.to_s } +
      publications.pluck(:id).map { |x| 'pub_' + x.to_s }
    child_nodes = []

    children.each do |child|
      if node = child.to_node(selected, ignore_count)
        child_nodes.push node
        ids.concat node[:a_attr][:ids]
      end
    end

    ids.uniq!
    count = ids.length
    if ignore_count or count > 0 or !child_nodes.empty?
      {
        id: id,
        text: title + (count > 0 ? " [#{count}]" : ''),
        children: child_nodes,
        a_attr: { ids: ids },
        state: { selected: selected == self, opened: selected == self }
      }
    end
  end

  def get_transitive_related(type)
    related = get_related(type)
    children.each do |child|
      related += child.get_transitive_related(type)
    end
    related.uniq
  end

  private

  def get_json(url)
    JSON.parse(open(url, "Authorization" => "apikey token=#{Seek::Config.bioportal_api_key}").read)
  end
end
