require 'grouped_pagination'
require 'acts_as_uniquely_identifiable'

class Assay < ActiveRecord::Base    
  
  belongs_to :assay_type
  belongs_to :technology_type  
  belongs_to :study  
  belongs_to :owner, :class_name=>"Person"
  belongs_to :assay_class
  has_many :assay_organisms, :dependent=>:destroy
  has_many :organisms, :through=>:assay_organisms
  has_many :strains, :through=>:assay_organisms

  has_many :assay_assets, :dependent => :destroy
  
  has_many :data_file_versions, :through => :assay_assets, :source => :asset, :source_type => "DataFile::Version"
  has_many :sop_versions, :through => :assay_assets, :source => :asset, :source_type => "Sop::Version"
  has_many :model_versions, :through => :assay_assets, :source => :asset, :source_type => "Model::Version"
  has_many :data_file_masters, :through => :assay_assets, :source => :asset, :source_type => "DataFile"
  has_many :sop_masters, :through => :assay_assets, :source => :asset, :source_type => "Sop"
  has_many :model_masters, :through => :assay_assets, :source => :asset, :source_type => "Model"
  
  def data_files; data_file_masters + data_file_versions; end
  def models; model_masters + model_versions; end
  def sops; sop_masters + sop_versions; end

  has_one :investigation,:through=>:study    

  has_many :assets,:through=>:assay_assets

  validates_presence_of :title
  validates_presence_of :assay_type
  validates_presence_of :technology_type, :unless=>:is_modelling?
  validates_presence_of :study, :message=>" must be selected"
  validates_presence_of :owner
  validates_presence_of :assay_class

  has_many :favourites, 
           :as => :resource, 
           :dependent => :destroy
          
  acts_as_solr(:fields=>[:description,:title],:include=>[:assay_type,:technology_type,:organisms,:strains]) if SOLR_ENABLED
  
  before_save :update_first_letter
  
  grouped_pagination
  
  acts_as_uniquely_identifiable
  
  def short_description
    type=assay_type.nil? ? "No type" : assay_type.title
   
    "#{title} (#{type})"
  end

  def project
    investigation.nil? ? nil : investigation.project
  end

  def can_edit? user
    project.pals.include?(user.person) || user.person == owner
  end

  def can_delete? user
    can_edit?(user) && data_files.empty? && sops.empty?
  end

  #returns true if this is a modelling class of assay
  def is_modelling?
    return !assay_class.nil? && assay_class.key=="MODEL"
  end

  #returns true if this is an experimental class of assay
  def is_experimental?
    return !assay_class.nil? && assay_class.key=="EXP"
  end
  
  def update_first_letter
    self.first_letter = strip_first_letter(title)
  end
  
  #Relate an asset to this assay with a specific relationship type
  def relate(asset, r_type=nil)
    assay_asset = AssayAsset.find_by_asset_id_and_assay_id(asset, self) || AssayAsset.new()
    assay_asset.assay = self
    assay_asset.asset = asset
    assay_asset.relationship_type = r_type unless r_type.nil?     
    assay_asset.save
  end

  #Associates and organism with the assay
  #organism may be either an ID or Organism instance
  #strain_title should be the String for the strain
  #culture_growth should be the culture growth instance
  def associate_organism(organism,strain_title=nil,culture_growth_type=nil)
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
    assay_organism.save!
  end
  
  def assets
    (data_files + models + sops).collect {|a| a.latest_version} |  (data_file_versions + model_versions + sop_versions)
  end
  
end
