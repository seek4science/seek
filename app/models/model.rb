class Model < ApplicationRecord

  include Seek::Rdf::RdfGeneration

  #searchable must come before acts_as_asset call
  searchable(:auto_index=>false) do
    text :organism_terms, :human_disease_terms, :model_contents_for_search
    text :model_format do
      model_format.try(:title)
    end
    text :model_type do
      model_type.try(:title)
    end
    text :recommended_environment do
      recommended_environment.try(:title)
    end
  end if Seek::Config.solr_enabled

  acts_as_asset

  validates :projects, presence: true, projects: { self: true }, unless: Proc.new {Seek::Config.is_virtualliver }

  acts_as_doi_parent(child_accessor: :versions)

  include Seek::Models::ModelExtraction

  before_save :check_for_sbml_format

  #FIXME: model_images seems to be to keep persistence of old images, wheras model_image is just the current_image
  has_many :model_images, inverse_of: :model
  belongs_to :model_image, inverse_of: :model

  has_many :content_blobs, -> (r) { where('content_blobs.asset_version =?', r.version) }, :as => :asset, :foreign_key => :asset_id

  belongs_to :organism
  belongs_to :human_disease
  belongs_to :recommended_environment,:class_name=>"RecommendedModelEnvironment"
  belongs_to :model_type
  belongs_to :model_format

  has_filter organism: Seek::Filtering::Filter.new(
      value_field: 'organisms.id',
      label_field: 'organisms.title',
      includes: [:organism]
  )

  has_filter  :model_type, :model_format, :recommended_environment
  has_filter modelling_analysis_type: Seek::Filtering::Filter.new(
      value_field: 'assays.assay_type_uri',
      label_mapping: ->(values) {
        values.map do |value|
          Seek::Ontologies::ModellingAnalysisTypeReader.instance.class_hierarchy.hash_by_uri[value]&.label
        end
      },
      joins: [:assays]
  )

  explicit_versioning(version_column: 'version', sync_ignore_columns: ['doi']) do
    include Seek::Models::ModelExtraction
    acts_as_doi_mintable(proxy: :parent, general_type: 'Model')
    acts_as_versioned_resource
    acts_as_favouritable

    belongs_to :model_image
    belongs_to :organism
    belongs_to :human_disease
    belongs_to :recommended_environment,:class_name=>"RecommendedModelEnvironment"
    belongs_to :model_type
    belongs_to :model_format

    has_many :content_blobs, -> (r) { where('content_blobs.asset_version = ? AND content_blobs.asset_type = ?', r.version, r.parent.class.name) },
            primary_key: :model_id, foreign_key: :asset_id

    def model_format
      if read_attribute(:model_format_id).nil? && contains_sbml?
        ModelFormat.sbml.first
      else
        super
      end
    end
  end

  def organism_terms
    if organism
      organism.searchable_terms
    else
      []
    end
  end

  def human_disease_terms
    if human_disease
      human_disease.searchable_terms
    else
      []
    end
  end

  #defines that this is a user_creatable object, and appears in the "New Object" gadget
  def self.user_creatable?
    Seek::Config.models_enabled
  end

  def model_format
    if read_attribute(:model_format_id).nil? && contains_sbml?
      ModelFormat.sbml.first
    else
      super
    end
  end

  private

  def check_for_sbml_format
    self.model_format = self.model_format
  end

end
