

class Assay < ActiveRecord::Base

  include Seek::Rdf::RdfGeneration
  include Seek::Ontologies::AssayOntologyTypes
  include Seek::Taggable
  include Seek::ProjectHierarchies::ItemsProjectsExtension if Seek::Config.project_hierarchy_enabled

  #needs to be declared before acts_as_isa, else ProjectCompat module gets pulled in
  def projects
    study.try(:projects) || []
  end

  acts_as_isa

  acts_as_annotatable :name_field=>:title

  belongs_to :institution
  has_and_belongs_to_many :samples
  belongs_to :study
  belongs_to :owner, :class_name=>"Person"
  belongs_to :assay_class
  has_many :assay_organisms, :dependent=>:destroy
  has_many :organisms, :through=>:assay_organisms
  has_many :strains, :through=>:assay_organisms
  has_many :tissue_and_cell_types,:through => :assay_organisms

  has_many :assay_assets, :dependent => :destroy

  #FIXME: These should be reversed, with the concrete version becoming the primary case, and versioned assets becoming secondary
  # i.e. - so data_files returnes [DataFile], and data_file_masters is replaced with versioned_data_files, returning [DataFile::Version]
  has_many :data_files, :class_name => "DataFile::Version", :finder_sql => Proc.new{self.asset_sql("DataFile")}
  has_many :sops, :class_name => "Sop::Version", :finder_sql => Proc.new{self.asset_sql("Sop")}
  has_many :models, :class_name => "Model::Version", :finder_sql => Proc.new{self.asset_sql("Model")}

  has_many :data_file_masters, :through => :assay_assets, :source => :asset, :source_type => "DataFile"
  has_many :sop_masters, :through => :assay_assets, :source => :asset, :source_type => "Sop"
  has_many :model_masters, :through => :assay_assets, :source => :asset, :source_type => "Model"
  has_many :relationships,
           :class_name => 'Relationship',
           :as => :subject,
           :dependent => :destroy

  has_one :investigation,:through=>:study

  validates_presence_of :assay_type_uri
  validates_presence_of :technology_type_uri, :unless=>:is_modelling?
  validates_presence_of :study, :message=>" must be selected"
  validates_presence_of :owner
  validates_presence_of :assay_class

  validate :no_sample_for_modelling_assay

  before_validation :default_assay_and_technology_type

  #a temporary store of added assets - see AssayReindexer
  attr_reader :pending_related_assets

  alias_attribute :contributor, :owner

  searchable(:auto_index=>false) do
    text :organism_terms, :assay_type_label,:technology_type_label

    text :strains do
      strains.compact.map{|s| s.title}
    end
  end if Seek::Config.solr_enabled


  def project_ids
    projects.map(&:id)
  end

  def default_contributor
    User.current_user.try :person
  end

  def asset_sql(asset_class)
    asset_class_underscored = asset_class.underscore
    'SELECT '+ asset_class_underscored +'_versions.* FROM ' + asset_class_underscored + '_versions ' +
    'INNER JOIN assay_assets ' + 
    'ON assay_assets.asset_id = ' + asset_class_underscored + '_id ' + 
    'AND assay_assets.asset_type = \'' + asset_class + '\' ' + 
    'WHERE (assay_assets.version = ' + asset_class_underscored + '_versions.version ' +
    "AND assay_assets.assay_id = #{self.id})"
  end



  ["data_file","sop","publication"].each do |type|
    eval <<-END_EVAL
      #related items hash will use data_file_masters instead of data_files, etc. (sops, models)
      def related_#{type.pluralize}
        #{type}_masters
      end
    END_EVAL
  end

  def related_models
    is_modelling? ? model_masters : []
  end



  def short_description
    type= self.assay_type_label.nil? ? "No type" : self.assay_type_label
   
    "#{self.title} (#{type})"
  end

  def state_allows_delete? *args
    assets.empty? && related_publications.empty? && super
  end

  #returns true if this is a modelling class of assay
  def is_modelling?
    return assay_class && assay_class.is_modelling?
  end

  #returns true if this is an experimental class of assay
  def is_experimental?
    return !assay_class.nil? && assay_class.key=="EXP"
  end

  
  #Create or update relationship of this assay to an asset, with a specific relationship type and version  
  def relate(asset, r_type=nil)
    assay_asset = assay_assets.detect {|aa| aa.asset == asset}

    if assay_asset.nil?
      assay_asset = AssayAsset.new
      assay_asset.assay = self             
    end
    
    assay_asset.asset = asset
    assay_asset.version = asset.version
    assay_asset.relationship_type = r_type unless r_type.nil?
    assay_asset.save if assay_asset.changed?

    @pending_related_assets ||= []
    @pending_related_assets << asset

    return assay_asset
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
  
  def assets
    asset_masters.collect {|a| a.latest_version} |  (data_files + models + sops)
  end

  def asset_masters
    data_file_masters + model_masters + sop_masters
  end
  
  def publication_masters
    self.relationships.select {|a| a.other_object_type == "Publication"}.collect { |a| a.other_object }
  end

  def related_asset_ids asset_type
    self.assay_assets.select {|a| a.asset_type == asset_type}.collect { |a| a.asset_id }
  end

  def avatar_key
    type = is_modelling? ? "modelling" : "experimental"
    "assay_#{type}_avatar"
  end

  def clone_with_associations
    new_object= self.dup
    new_object.policy = self.policy.deep_copy
    new_object.sop_masters = self.try(:sop_masters)

    new_object.model_masters = self.try(:model_masters)
    new_object.sample_ids = self.try(:sample_ids)
    new_object.assay_organisms = self.try(:assay_organisms)
    return new_object
  end

  def either_samples_or_organisms_for_experimental_assay
     errors[:base] << "You should associate a #{I18n.t('assays.experimental_assay')} with either samples or organisms or both" if !is_modelling? && samples.empty? && assay_organisms.empty?
  end

  def no_sample_for_modelling_assay
    #FIXME: allows at the moment until fixtures and factories are updated: JIRA: SYSMO-734
    errors[:base] << "You cannot associate a #{I18n.t('assays.modelling_analysis')} with a sample" if is_modelling? && !samples.empty? && !Seek::Config.is_virtualliver
  end

  def organism_terms
    organisms.collect{|o| o.searchable_terms}.flatten
  end

  def self.user_creatable?
    Seek::Config.assays_enabled
  end


end
