class Assay < ActiveRecord::Base
  include Seek::Rdf::RdfGeneration
  include Seek::Ontologies::AssayOntologyTypes
  include Seek::Taggable
  include Seek::ProjectHierarchies::ItemsProjectsExtension if Seek::Config.project_hierarchy_enabled



  # needs to before acts_as_isa - otherwise auto_index=>false is overridden by Seek::Search::CommonFields
  if Seek::Config.solr_enabled
    searchable(auto_index: false) do
      text :organism_terms, :assay_type_label, :technology_type_label

      text :strains do
        strains.compact.map(&:title)
      end
    end
  end

  # needs to be declared before acts_as_isa, else ProjectAssociation module gets pulled in
  belongs_to :study
  has_many :projects, through: :study

  acts_as_isa
  acts_as_snapshottable

  belongs_to :institution


  belongs_to :assay_class
  has_many :assay_organisms, dependent: :destroy, inverse_of: :assay
  has_many :organisms, through: :assay_organisms, inverse_of: :assays
  has_many :strains, through: :assay_organisms
  has_many :tissue_and_cell_types, through: :assay_organisms


  before_save { assay_assets.each(&:set_version) }
  has_many :assay_assets, dependent: :destroy, inverse_of: :assay, autosave: true

  has_many :data_files, through: :assay_assets, source: :asset, source_type: 'DataFile', inverse_of: :assays
  has_many :sops, through: :assay_assets, source: :asset, source_type: 'Sop', inverse_of: :assays
  has_many :models, through: :assay_assets, source: :asset, source_type: 'Model', inverse_of: :assays
  has_many :samples, through: :assay_assets, source: :asset, source_type: 'Sample', inverse_of: :assays
  has_many :documents, through: :assay_assets, source: :asset, source_type: 'Document', inverse_of: :assays

  has_one :investigation, through: :study

  validates_presence_of :assay_type_uri
  validates_presence_of :technology_type_uri, unless: :is_modelling?
  validates_presence_of :contributor
  validates_presence_of :assay_class
  validates :study, presence: { message: ' must be selected and valid' }, projects: true

  before_validation :default_assay_and_technology_type

  # a temporary store of added assets - see AssayReindexer
  attr_reader :pending_related_assets

  enforce_authorization_on_association :study, :view

  def default_contributor
    User.current_user.try :person
  end

  def short_description
    type = assay_type_label.nil? ? 'No type' : assay_type_label

    "#{title} (#{type})"
  end

  def state_allows_delete?(*args)
    assets.empty? && publications.empty? && super
  end

  # returns true if this is a modelling class of assay
  def is_modelling?
    assay_class && assay_class.is_modelling?
  end

  # returns true if this is an experimental class of assay
  def is_experimental?
    !assay_class.nil? && assay_class.key == 'EXP'
  end

  # Create or update relationship of this assay to another, with a specific relationship type and version
  def associate(asset, options = {})
    if asset.is_a?(Organism)
      associate_organism(asset)
    else
      assay_asset = assay_assets.detect { |aa| aa.asset == asset }

      if assay_asset.nil?
        assay_asset = assay_assets.build
      end

      assay_asset.asset = asset
      assay_asset.version = asset.version if asset && asset.respond_to?(:version)
      r_type = options.delete(:relationship)
      assay_asset.relationship_type = r_type unless r_type.nil?

      direction = options.delete(:direction)
      assay_asset.direction = direction unless direction.nil?
      assay_asset.save if assay_asset.changed?

      @pending_related_assets ||= []
      @pending_related_assets << asset

      assay_asset
    end
  end

  def self.simple_associated_asset_types
    [:models, :sops, :publications, :documents]
  end

  # Associations where there is additional metadata on the association, i.e. `direction`
  def self.complex_associated_asset_types
    [:data_files, :samples]
  end

  def assets
    (self.class.complex_associated_asset_types + self.class.simple_associated_asset_types).inject([]) do |assets, type|
      assets + send(type)
    end
  end

  def incoming
    assay_assets.incoming.collect(&:asset)
  end

  def outgoing
    assay_assets.outgoing.collect(&:asset)
  end

  def validation_assets
    assay_assets.validation.collect(&:asset)
  end

  def construction_assets
    assay_assets.construction.collect(&:asset)
  end

  def simulation_assets
    assay_assets.simulation.collect(&:asset)
  end

  def avatar_key
    type = is_modelling? ? 'modelling' : 'experimental'
    "assay_#{type}_avatar"
  end

  def clone_with_associations
    new_object = dup
    new_object.policy = policy.deep_copy
    new_object.assay_assets = assay_assets.select { |aa| self.class.complex_associated_asset_types.include?(aa.asset_type.underscore.pluralize.to_sym) }.map(&:dup)
    self.class.simple_associated_asset_types.each do |type|
      new_object.send("#{type}=", try(type))
    end
    new_object.assay_organisms = try(:assay_organisms)
    new_object
  end

  def organism_terms
    organisms.collect(&:searchable_terms).flatten
  end

  def self.user_creatable?
    Seek::Config.assays_enabled
  end

  # Associates and organism with the assay
  # organism may be either an ID or Organism instance
  # strain_id should be the id of the strain
  # culture_growth should be the culture growth instance
  def associate_organism(organism, strain_id = nil, culture_growth_type = nil, tissue_and_cell_type_id = '0', tissue_and_cell_type_title = nil)
    organism = Organism.find(organism) if organism.is_a?(Numeric) || organism.is_a?(String)
    strain = organism.strains.find_by_id(strain_id)
    assay_organism = AssayOrganism.new(assay: self, organism: organism, culture_growth_type: culture_growth_type, strain: strain)

    unless AssayOrganism.exists_for?(strain, organism, self, culture_growth_type)
      assay_organisms << assay_organism
    end

    tissue_and_cell_type = nil
    unless tissue_and_cell_type_title.blank?
      if tissue_and_cell_type_id == '0'
        found = TissueAndCellType.where(title: tissue_and_cell_type_title).first
        unless found
          tissue_and_cell_type = TissueAndCellType.create!(title: tissue_and_cell_type_title) if !tissue_and_cell_type_title.nil? && tissue_and_cell_type_title != ''
        end
      else
        tissue_and_cell_type = TissueAndCellType.find_by_id(tissue_and_cell_type_id)
      end
    end
    assay_organism.tissue_and_cell_type = tissue_and_cell_type
  end

  # overides that from Seek::RDF::RdfGeneration, as Assay entity depends upon the AssayClass (modelling, or experimental) of the Assay
  def rdf_type_entity_fragment
    { 'EXP' => 'Experimental_assay', 'MODEL' => 'Modelling_analysis' }[assay_class.key]
  end

  def samples_attributes= attributes
    set_assay_assets_for('Sample', attributes)
  end

  def data_files_attributes= attributes
    set_assay_assets_for('DataFile', attributes)
  end

  private

  def set_assay_assets_for(type, attributes)
    type_assay_assets, other_assay_assets = self.assay_assets.partition { |aa| aa.asset_type == type }
    new_type_assay_assets = []

    attributes.each do |attrs|
      attrs.merge!(asset_type: type)
      existing = type_assay_assets.detect { |aa| aa.asset_id.to_s == attrs['asset_id'] }
      if existing
        new_type_assay_assets << existing.tap { |e| e.assign_attributes(attrs) }
      else
        aa = self.assay_assets.build(attrs)
        if aa.asset && aa.asset.can_view?
          new_type_assay_assets << aa
        end
      end
    end

    self.assay_assets = (other_assay_assets + new_type_assay_assets)
    self.assay_assets
  end
end
