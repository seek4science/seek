class Assay < ActiveRecord::Base

  include Seek::Rdf::RdfGeneration
  include Seek::Ontologies::AssayOntologyTypes
  include Seek::Taggable
  include Seek::ProjectHierarchies::ItemsProjectsExtension if Seek::Config.project_hierarchy_enabled

  #needs to be declared before acts_as_isa, else ProjectAssociation module gets pulled in
  def projects
    study.try(:projects) || []
  end

  #needs to before acts_as_isa - otherwise auto_index=>false is overridden by Seek::Search::CommonFields
  searchable(:auto_index=>false) do
    text :organism_terms, :assay_type_label,:technology_type_label

    text :strains do
      strains.compact.map{|s| s.title}
    end
  end if Seek::Config.solr_enabled

  acts_as_isa
  acts_as_snapshottable

  acts_as_annotatable :name_field=>:title

  belongs_to :institution

  belongs_to :study
  belongs_to :owner, :class_name=>"Person"
  belongs_to :assay_class
  has_many :assay_organisms, dependent: :destroy, inverse_of: :assay
  has_many :organisms, through: :assay_organisms, inverse_of: :assays
  has_many :strains, :through=>:assay_organisms
  has_many :tissue_and_cell_types,:through => :assay_organisms

  has_many :assay_assets, :dependent => :destroy

  has_many :data_files, :through => :assay_assets, :source => :asset, :source_type => "DataFile"
  has_many :sops, :through => :assay_assets, :source => :asset, :source_type => "Sop"
  has_many :models, :through => :assay_assets, :source => :asset, :source_type => "Model"
  has_many :samples, :through => :assay_assets, :source => :asset, :source_type => "Sample"

  has_one :investigation,:through=>:study

  validates_presence_of :assay_type_uri
  validates_presence_of :technology_type_uri, :unless=>:is_modelling?
  validates_presence_of :study, :message=>" must be selected"
  validates_presence_of :owner
  validates_presence_of :assay_class


  before_validation :default_assay_and_technology_type

  #a temporary store of added assets - see AssayReindexer
  attr_reader :pending_related_assets

  alias_attribute :contributor, :owner

  def project_ids
    projects.map(&:id)
  end

  def default_contributor
    User.current_user.try :person
  end

  def short_description
    type= self.assay_type_label.nil? ? "No type" : self.assay_type_label
   
    "#{self.title} (#{type})"
  end

  def state_allows_delete? *args
    assets.empty? && publications.empty? && super
  end

  #returns true if this is a modelling class of assay
  def is_modelling?
    return assay_class && assay_class.is_modelling?
  end

  #returns true if this is an experimental class of assay
  def is_experimental?
    return !assay_class.nil? && assay_class.key=="EXP"
  end

  
  #Create or update relationship of this assay to another, with a specific relationship type and version
  def associate(asset, options = {})
    if asset.is_a?(Organism)
      associate_organism(asset)
    else
      assay_asset = assay_assets.detect {|aa| aa.asset == asset}

      if assay_asset.nil?
        assay_asset = AssayAsset.new
        assay_asset.assay = self
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

      return assay_asset
    end
  end

  def assets
    data_files + models + sops + publications + samples
  end

  def avatar_key
    type = is_modelling? ? "modelling" : "experimental"
    "assay_#{type}_avatar"
  end

  def clone_with_associations
    new_object= self.dup
    new_object.policy = self.policy.deep_copy
    new_object.sops = self.try(:sops)

    new_object.models = self.try(:models)
    new_object.assay_organisms = self.try(:assay_organisms)
    return new_object
  end

  def organism_terms
    organisms.collect{|o| o.searchable_terms}.flatten
  end

  def self.user_creatable?
    Seek::Config.assays_enabled
  end

  #Associates and organism with the assay
  #organism may be either an ID or Organism instance
  #strain_id should be the id of the strain
  #culture_growth should be the culture growth instance
  def associate_organism(organism,strain_id=nil,culture_growth_type=nil,tissue_and_cell_type_id="0",tissue_and_cell_type_title=nil)
    organism = Organism.find(organism) if organism.kind_of?(Numeric) || organism.kind_of?(String)
    strain=organism.strains.find_by_id(strain_id)
    assay_organism=AssayOrganism.new(:assay=>self,:organism=>organism,:culture_growth_type=>culture_growth_type,:strain=>strain)

    unless AssayOrganism.exists_for?(strain,organism,self,culture_growth_type)
      self.assay_organisms << assay_organism
    end

    tissue_and_cell_type=nil
    if !tissue_and_cell_type_title.blank?
      if ( tissue_and_cell_type_id =="0" )
        found = TissueAndCellType.where(:title => tissue_and_cell_type_title).first
        unless found
          tissue_and_cell_type = TissueAndCellType.create!(:title=> tissue_and_cell_type_title) if (!tissue_and_cell_type_title.nil? && tissue_and_cell_type_title!="")
        end
      else
        tissue_and_cell_type = TissueAndCellType.find_by_id(tissue_and_cell_type_id)
      end
    end
    assay_organism.tissue_and_cell_type = tissue_and_cell_type
  end

end
