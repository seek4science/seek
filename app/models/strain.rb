class Strain < ApplicationRecord

  include Seek::Rdf::RdfGeneration
  include Seek::ActsAsCachedTree
  include Seek::Subscribable
  include Seek::Biosamples::PhenoTypesAndGenoTypes
  include Seek::Search::BackgroundReindexing
  include Seek::Stats::ActivityCounts

  acts_as_authorized
  acts_as_uniquely_identifiable
  acts_as_favouritable

  include Seek::Taggable
  grouped_pagination

  belongs_to :organism

  has_many :assay_organisms
  has_many :assays,:through=>:assay_organisms
  has_many :sample_resource_links, as: :resource, dependent: :destroy
  has_many :samples, through: :sample_resource_links

  before_destroy :destroy_genotypes_phenotypes

  scope :without_default, -> { where(is_dummy: false) }

  delegate :ncbi_uri, :to=>:organism

  validates_presence_of :title, :organism
  validates_presence_of :projects, :unless => Proc.new{|strain| strain.is_dummy? || Seek::Config.is_virtualliver}

  alias_attribute :description, :comment

  include Seek::Search::CommonFields

  searchable(:auto_index=>false) do
      text :synonym
      text :genotype_info do
        genotype_info
      end
      text :phenotype_info do
        phenotype_info
      end
      text :provider_name do
        provider_name
      end
      text :provider_id do
        provider_id
      end
  end if Seek::Config.solr_enabled

  def is_default?
    title=="default" && is_dummy==true
  end

  def self.default_strain_for_organism organism
    organism = Organism.find(organism) unless organism.is_a?(Organism)
    strain = Strain.where(:organism_id=>organism.id,:is_dummy=>true).first
    unless strain
      gene = Gene.find_by_title('wild-type') || Gene.create(:title => 'wild-type')
      genotype = Genotype.new(:gene => gene)
      phenotype = Phenotype.new(:description => 'wild-type')
      strain = Strain.create :organism=>organism,:is_dummy=>true,:title=>"default",:genotypes=>[genotype],:phenotypes=>[phenotype]
    end
    strain
  end

  #gives the long title that includes genotype and phenotype details
  def info
    title + " (" + genotype_info + ' / ' + phenotype_info + ')'
  end

  def can_delete? user=User.current_user
    if contributor
      super
    else
      organism && organism.can_delete?(user)
    end
  end

  #defines that this is a user_creatable object, and appears in the "New Object" gadget
  def self.user_creatable?
    Seek::Config.organisms_enabled
  end

  def default_policy
    Policy.registered_users_accessible_policy
  end

  def clone_with_associations
    new_object= self.dup
    new_object.policy = self.policy.deep_copy
    new_object.projects = self.projects
    new_object.genotypes = self.genotypes
    new_object.phenotypes = self.phenotypes

    return new_object
  end

  def related_people
    Person.where(id: related_person_ids)
  end

  def related_person_ids
    contributor_id
  end
end
