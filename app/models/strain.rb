require 'grouped_pagination'
require 'acts_as_cached_tree'

class Strain < ActiveRecord::Base
  include Seek::Rdf::RdfGeneration

  belongs_to :organism
  has_many :genotypes
  has_many :phenotypes
  accepts_nested_attributes_for :genotypes,:allow_destroy=>true
  accepts_nested_attributes_for :phenotypes,:allow_destroy=>true
  has_many :specimens

  has_many :assay_organisms
  has_many :assays,:through=>:assay_organisms

  before_destroy :destroy_genotypes_phenotypes
  scope :by_title

  validates_presence_of :title, :organism

  scope :without_default,where(:is_dummy=>false)

  include ActsAsCachedTree
  include Subscribable
  acts_as_authorized
  acts_as_uniquely_identifiable
  acts_as_favouritable
  acts_as_annotatable :name_field=>:title
  include Seek::Taggable

  validates_presence_of :projects, :unless => Proc.new{|s| s.is_dummy? || Seek::Config.is_virtualliver}

  grouped_pagination

  searchable(:ignore_attribute_changes_of=>[:updated_at]) do
      text :searchable_terms
  end if Seek::Config.solr_enabled

  def searchable_terms
      text=[]
      text << title
      text << synonym
      text << comment
      text << provider_name
      text << provider_id
      text << searchable_tags
      genotypes.compact.each do |g|
        text << g.gene.try(:title)
      end
      phenotypes.compact.each do |p|
        text << p.description
      end
      text
  end

  def is_default?
    title=="default" && is_dummy==true
  end

  def ncbi_uri
    unless organism.bioportal_concept.nil? || organism.bioportal_concept.concept_uri.blank?
      "http://purl.obolibrary.org/obo/"+organism.bioportal_concept.concept_uri.gsub(":","_")
    else
      nil
    end
  end

  def is_default?
    title=="default" && is_dummy==true
  end

  def self.default_strain_for_organism organism
    organism = Organism.find(organism) unless organism.is_a?(Organism)
    strain = Strain.where(:organism_id=>organism.id,:is_dummy=>true).first
    if strain.nil?
      gene = Gene.find_by_title('wild-type') || Gene.create(:title => 'wild-type')
      genotype = Genotype.new(:gene => gene)
      phenotype = Phenotype.new(:description => 'wild-type')
      strain = Strain.create :organism=>organism,:is_dummy=>true,:title=>"default",:genotypes=>[genotype],:phenotypes=>[phenotype]
    end
    strain
  end

  #gives the long title that includes genotype and phenotype details
  def info
    title + " (" + genotype_info + '/' + phenotype_info + ')'
  end

  def genotype_info
    genotype_detail = []
    genotypes.each do |genotype|
      genotype_detail << genotype.modification.try(:title).to_s + ' ' + genotype.gene.try(:title).to_s if genotype.gene
    end
    genotype_detail = genotype_detail.blank? ? 'wild-type' : genotype_detail.join('; ')
    genotype_detail
  end

  def phenotype_info
    phenotype_detail = []
    phenotypes.each do |phenotype|
      phenotype_detail << phenotype.try(:description) unless phenotype.try(:description).blank?
    end
    phenotype_detail = phenotype_detail.blank? ? 'wild-type' : phenotype_detail.join('; ')
    phenotype_detail
  end

  def parent_strain
    parent_strain = Strain.find_by_id(parent_id)
    parent_strain.nil? ? '' : (parent_strain.title + "(Seek ID=#{parent_strain.id})")
  end

  def state_allows_delete? *args
    (specimens.empty? || ((specimens.count == 1) && specimens.first.is_dummy? && specimens.first.samples.empty?)) && super
  end

  def destroy_genotypes_phenotypes
    genotypes = self.genotypes
    phenotypes = self.phenotypes
    genotypes.each do |g|
      if g.specimen.nil?
        g.destroy
      else
        g.strain_id = nil
        g.save
      end
    end
    phenotypes.each do |p|
      if p.specimen.nil?
        p.destroy
      else
        p.strain_id = nil
        p.save
      end
    end
  end

  #defines that this is a user_creatable object, and appears in the "New Object" gadget
  def self.user_creatable?
    true
  end
end
