class Strain < ActiveRecord::Base
  belongs_to :organism
  has_many :genotypes, :dependent => :destroy
  has_many :phenotypes, :dependent => :destroy
  has_many :specimens

  named_scope :by_title

  validates_presence_of :title, :organism

  named_scope :without_default,:conditions=>{:is_dummy=>false}

  include ActsAsCachedTree
  acts_as_authorized
  acts_as_uniquely_identifiable

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

  def can_delete?
    super && (specimens.empty? || ((specimens.count == 1) && specimens.first.is_dummy? && specimens.first.samples.empty?))
  end
end
