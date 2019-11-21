class Study < ApplicationRecord

  include Seek::Rdf::RdfGeneration
  include Seek::ProjectHierarchies::ItemsProjectsExtension if Seek::Config.project_hierarchy_enabled

  searchable(:auto_index => false) do
    text :experimentalists
    text :person_responsible do
      person_responsible.try(:name)
    end
  end if Seek::Config.solr_enabled

  belongs_to :investigation
  has_many :projects, through: :investigation
  has_filter :project

  #FIXME: needs to be declared before acts_as_isa, else ProjectAssociation module gets pulled in
  acts_as_isa
  acts_as_snapshottable

  has_many :assays
  has_many :assay_publications, through: :assays, source: :publications
  has_one :external_asset, as: :seek_entity, dependent: :destroy

  has_one :custom_metadata, as: :item
  accepts_nested_attributes_for :custom_metadata

  belongs_to :person_responsible, :class_name => "Person"

  validates :investigation, presence: { message: "Investigation is blank or invalid" }, projects: true

  enforce_authorization_on_association :investigation, :view

  %w[data_file sop model document].each do |type|
    has_many "#{type}_versions".to_sym, -> { distinct }, through: :assays
    has_many "related_#{type.pluralize}".to_sym, -> { distinct }, through: :assays, source: type.pluralize.to_sym
  end

  def self.unzip_batch file_path
      unzipped_files = Zip::File.open(file_path) 

      data_files = []
      studies = []
      unzipped_files.entries.each do |file|
        if file.name.starts_with?('data') && file.ftype != :directory
          data_files << file
        elsif file.ftype == :file
          studies << file
        end
      end
      [data_files, studies]
  end

  def assets
    related_data_files + related_sops + related_models + related_publications + related_documents
  end

  def state_allows_delete? *args
    assays.empty? && super
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
    joins(:projects).where(investigations: { investigations_projects: { project_id: projects } })
  end

  def related_publication_ids
    publication_ids | assay_publication_ids
  end

  def related_person_ids
    ids = super
    ids << person_responsible_id if person_responsible_id
    ids.uniq
  end

  def self.user_creatable?
    Seek::Config.studies_enabled
  end
end
