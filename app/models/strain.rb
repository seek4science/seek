require 'grouped_pagination'
require 'acts_as_authorized'

class Strain < ActiveRecord::Base
  belongs_to :organism
  has_many :genotypes, :dependent =>  :nullify
  has_many :phenotypes, :dependent =>  :nullify
  accepts_nested_attributes_for :genotypes,:allow_destroy=>true
  accepts_nested_attributes_for :phenotypes,:allow_destroy=>true
  has_many :specimens

  before_destroy :destroy_genotypes_phenotypes
  named_scope :by_title

  validates_presence_of :title, :organism

  named_scope :without_default,:conditions=>{:is_dummy=>false}

  include ActsAsCachedTree
  include Subscribable
  acts_as_authorized
  acts_as_uniquely_identifiable
  acts_as_favouritable
  acts_as_annotatable :name_field=>:title
  include Seek::Taggable

  validates_presence_of :projects, :unless => Proc.new{|s| s.is_dummy? || Seek::Config.is_virtualliver}

  grouped_pagination :pages=>("A".."Z").to_a, :default_page => Seek::Config.default_page(self.name.underscore.pluralize)

  searchable do
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

  def is_default?
    title=="default" && is_dummy==true
  end

  def self.default_strain_for_organism organism
    organism = Organism.find(organism) unless organism.is_a?(Organism)
    strain = Strain.find(:first,:conditions=>{:organism_id=>organism.id,:is_dummy=>true})
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

  def can_delete? *args
    super && (specimens.empty? || ((specimens.count == 1) && specimens.first.is_dummy? && specimens.first.samples.empty?))
  end

  def destroy_genotypes_phenotypes
    genotypes = self.genotypes
    phenotypes = self.phenotypes
    genotypes.each do |g|
      if g.specimen.nil?
        g.destroy
      end
    end
    phenotypes.each do |p|
      if p.specimen.nil?
        p.destroy
      end
    end
  end

  #defines that this is a user_creatable object, and appears in the "New Object" gadget
  def self.user_creatable?
    true
  end
end
