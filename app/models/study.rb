class Study < ApplicationRecord

  belongs_to :assignee, class_name: 'Person'

  searchable(:auto_index => false) do
    text :experimentalists
  end if Seek::Config.solr_enabled

  belongs_to :investigation
  has_many :projects, through: :investigation
  has_filter :project, :isa_json_compliance

  #FIXME: needs to be declared before acts_as_isa, else ProjectAssociation module gets pulled in
  acts_as_isa
  acts_as_snapshottable

  has_many :assays
  has_many :assay_publications, through: :assays, source: :publications

  has_many :assay_sops, through: :assays, source: :sops
  has_many :sop_versions, -> { distinct }, through: :assays
  has_many :assay_data_files, -> { distinct }, through: :assays, source: :data_files
  has_many :data_file_versions, -> { distinct }, through: :assays
  has_many :assay_samples, -> { distinct }, through: :assays, source: :samples
  has_many :observation_units
  has_many :observations_unit_data_files, -> { distinct }, through: :observation_units, source: :data_files
  has_many :observations_unit_samples, -> { distinct }, through: :observation_units, source: :samples

  has_one :external_asset, as: :seek_entity, dependent: :destroy

  has_and_belongs_to_many :sops

  has_and_belongs_to_many :sample_types

  validates :investigation, presence: { :message => "is blank or invalid" }, projects: true

  enforce_authorization_on_association :investigation, :view

  # the associated projects from the Investigation.
  # Overrides the :through :investigation, as that relies on being saved to the database first, causing validation issues
  def projects
    investigation&.projects  || []
  end

  def assay_streams
    assays.select(&:is_assay_stream?)
  end

  def state_allows_delete? *args
    assays.empty? && associated_samples_through_sample_type.empty? && super
  end

  def associated_samples_through_sample_type
    return [] if sample_types.nil?
    st_samples = []
    sample_types.map do |st|
      st.samples.map { |sts| st_samples.push sts }
    end
    st_samples
  end

  def is_isa_json_compliant?
    investigation.is_isa_json_compliant? && sample_types.any?
  end

  def clone_with_associations
    new_object = dup
    new_object.policy = policy.deep_copy
    new_object.publications = publications
    new_object
  end

  def external_asset_search_terms
    external_asset ? external_asset.search_terms : []
  end

  def self.filter_by_projects(projects)
    joins(:projects).where(investigations: {investigations_projects: {project_id: projects}})
  end

  %w[model document].each do |type|
    has_many "#{type}_versions".to_sym, -> { distinct }, through: :assays
    has_many "related_#{type.pluralize}".to_sym, -> { distinct }, through: :assays, source: type.pluralize.to_sym
  end

  # related

  def assets
    related_data_files + related_sops + related_models + related_publications + related_documents
  end
  def related_data_file_ids
    observations_unit_data_file_ids | assay_data_file_ids
  end

  def related_sample_ids
    observations_unit_sample_ids | assay_sample_ids
  end

  def related_samples
    Sample.where(id: related_sample_ids)
  end

  def related_publication_ids
    publication_ids | assay_publication_ids
  end

  def related_person_ids
    ids = super
    ids.uniq
  end

  def related_sop_ids
    sop_ids | assay_sop_ids
  end

  def positioned_assays
    assays.order(position: :asc)
  end

  def self.user_creatable?
    Seek::Config.studies_enabled

  end
end
