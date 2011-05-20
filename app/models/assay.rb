require 'acts_as_authorized'
class Assay < ActiveRecord::Base
  acts_as_isa
  cattr_accessor :organism_count
  # The following is basically the same as acts_as_authorized,
  # but instead of creating a project and contributor
  # I use the existing project method and owner attribute.
    alias_attribute :contributor, :owner

    def project_id
      project.try :id
    end

    before_save :policy_or_default

    belongs_to :policy, :autosave => true

    class_eval do
      extend Acts::Authorized::SingletonMethods
    end
    include Acts::Authorized::InstanceMethods
  #end of acts_as_authorized stuff

  acts_as_taggable
  belongs_to :institution
  belongs_to :sample
  belongs_to :assay_type
  belongs_to :technology_type  
  belongs_to :study  
  belongs_to :owner, :class_name=>"Person"
  belongs_to :assay_class
  has_many :assay_organisms, :dependent=>:destroy
  has_many :organisms, :through=>:assay_organisms
  has_many :strains, :through=>:assay_organisms

  has_many :assay_assets, :dependent => :destroy
  
  def self.asset_sql(asset_class)
    asset_class_underscored = asset_class.underscore
    'SELECT '+ asset_class_underscored +'_versions.* FROM ' + asset_class_underscored + '_versions ' +
    'INNER JOIN assay_assets ' + 
    'ON assay_assets.asset_id = ' + asset_class_underscored + '_id ' + 
    'AND assay_assets.asset_type = \'' + asset_class + '\' ' + 
    'WHERE (assay_assets.version = ' + asset_class_underscored + '_versions.version ' +
    'AND assay_assets.assay_id = #{self.id})' 
  end
  
  has_many :data_files, :class_name => "DataFile::Version", :finder_sql => self.asset_sql("DataFile")
  has_many :sops, :class_name => "Sop::Version", :finder_sql => self.asset_sql("Sop")
  has_many :models, :class_name => "Model::Version", :finder_sql => self.asset_sql("Model")
  
  has_many :data_file_masters, :through => :assay_assets, :source => :asset, :source_type => "DataFile"
  has_many :sop_masters, :through => :assay_assets, :source => :asset, :source_type => "Sop"
  has_many :model_masters, :through => :assay_assets, :source => :asset, :source_type => "Model"

  has_one :investigation,:through=>:study    

  has_many :assets,:through=>:assay_assets

  validates_presence_of :assay_type
  validates_presence_of :technology_type, :unless=>:is_modelling?
  validates_presence_of :study, :message=>" must be selected"
  validates_presence_of :owner
  validates_presence_of :assay_class
 # validates_presence_of :sample, :if => :organisms_are_missing?,:unless => :sample_is_missing?
 # validates_presence_of :organisms,:if => :sample_is_missing?,:unless => :organisms_are_missing?

  has_many :relationships, 
    :class_name => 'Relationship',
    :as => :subject,
    :dependent => :destroy
          
  acts_as_solr(:fields=>[:description,:title,:tag_counts],:include=>[:assay_type,:technology_type,:organisms,:strains]) if Seek::Config.solr_enabled
  
  def short_description
    type=assay_type.nil? ? "No type" : assay_type.title
   
    "#{title} (#{type})"
  end

  def project
    investigation.nil? ? nil : investigation.project
  end

  def can_delete? user=nil
    mixin_super(user) && assets.empty? && related_publications.empty?
  end

  #returns true if this is a modelling class of assay
  def is_modelling?
    return !assay_class.nil? && assay_class.key=="MODEL"
  end

  #returns true if this is an experimental class of assay
  def is_experimental?
    return !assay_class.nil? && assay_class.key=="EXP"
  end    
  
  #Create or update relationship of this assay to an asset, with a specific relationship type and version  
  def relate(asset, r_type=nil)
    assay_asset = assay_assets.select {|aa| aa.asset == asset}.first

    if assay_asset.nil?
      assay_asset = AssayAsset.new
      assay_asset.assay = self             
    end
    
    assay_asset.asset = asset
    assay_asset.version = asset.version
    assay_asset.relationship_type = r_type unless r_type.nil?
    assay_asset.save if assay_asset.changed?
    
    return assay_asset
  end

  #Associates and organism with the assay
  #organism may be either an ID or Organism instance
  #strain_title should be the String for the strain
  #culture_growth should be the culture growth instance
  def associate_organism(organism,strain_title=nil,culture_growth_type=nil,tissue_and_cell_type_id="0",tissue_and_cell_type_title=nil)

    organism = Organism.find(organism) if organism.kind_of?(Numeric) || organism.kind_of?(String)
    assay_organism=AssayOrganism.new
    assay_organism.assay = self
    assay_organism.organism = organism
    strain=nil
    if (strain_title && !strain_title.empty?)
      strain=organism.strains.find_by_title(strain_title)
      if strain.nil?
        strain=Strain.new(:title=>strain_title,:organism_id=>organism.id)
        strain.save!
      end
    end
    assay_organism.culture_growth_type = culture_growth_type unless culture_growth_type.nil?
    assay_organism.strain=strain

    tissue_and_cell_type=nil
    if tissue_and_cell_type_title && !tissue_and_cell_type_title.empty?
      if ( tissue_and_cell_type_id =="0" )
          found = TissueAndCellType.find(:first,:conditions => {:title => tissue_and_cell_type_title})
          unless found
          tissue_and_cell_type = TissueAndCellType.create!(:title=> tissue_and_cell_type_title) if (!tissue_and_cell_type_title.nil? && tissue_and_cell_type_title!="")
          end
      else
          tissue_and_cell_type = TissueAndCellType.find_by_id(tissue_and_cell_type_id)
      end
    end
    assay_organism.tissue_and_cell_type = tissue_and_cell_type

    existing = AssayOrganism.find(:first,:conditions => {:organism_id=> organism,
                                                          :assay_id => self,
                                                          :strain_id => strain,
                                                          :culture_growth_type_id => culture_growth_type,
                                                          :tissue_and_cell_type_id => tissue_and_cell_type})
    unless existing
    assay_organism.save!
    end
   
  end
  
  def assets
    (data_file_masters + model_masters + sop_masters).collect {|a| a.latest_version} |  (data_files + models + sops)
  end
  
  def related_publications
    self.relationships.select {|a| a.object_type == "Publication"}.collect { |a| a.object }
  end

  def related_asset_ids asset_type
    self.assay_assets.select {|a| a.asset_type == asset_type}.collect { |a| a.asset_id }
  end

  def avatar_key
    type = is_modelling? ? "modelling" : "experimental"
    "assay_#{type}_avatar"
  end

  def sample_is_missing?
    return sample_id.nil?
  end

  def organisms_are_missing?

    return organism_count == 0
  end


  def validate
    errors.add_to_base "Please specify either sample or organisms for assay!" if sample_is_missing? and organisms_are_missing?


  end

end
