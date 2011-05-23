require 'grouped_pagination'
require 'acts_as_authorized'

class Specimen < ActiveRecord::Base


  has_many :samples

  has_many :assets_creators, :dependent => :destroy, :as => :asset, :foreign_key => :asset_id
  has_many :creators, :class_name => "Person", :through => :assets_creators, :order=>'assets_creators.id'


  belongs_to :institution
  belongs_to :organism
  belongs_to :culture_growth_type
  belongs_to :strain

  alias_attribute :description, :comments
  alias_attribute :title, :donor_number


  validates_numericality_of :age, :only_integer => true, :greater_than=> 0, :allow_nil=> true, :message => "is not a positive integer"
  validates_presence_of :donor_number,:contributor,:lab_internal_number,:project,:institution

  validates_uniqueness_of :donor_number


  grouped_pagination :pages=>("A".."Z").to_a, :default_page => Seek::Config.default_page(self.name.underscore.pluralize)

  acts_as_authorized

  def age_in_weeks
    if !age.nil?
      age.to_s + " (weeks)"
    end
  end

  def can_delete? user=User.current_user
    samples.empty? && mixin_super(user)
  end

  def self.user_creatable?
    true
  end

  #Associates and organism with the specimen
  #organism may be either an ID or Organism instance
  #strain_title should be the String for the strain
  #culture_growth should be the culture growth instance
  def associate_organism(organism=nil,strain_title=nil,culture_growth_type=nil)

    organism = Organism.find(organism) if organism.kind_of?(Numeric) || organism.kind_of?(String)
    if organism && !organism.empty?
      self.organism = organism
    end
    strain=nil
    if (strain_title && !strain_title.empty?)
      strain=organism.strains.find_by_title(strain_title)
      if strain.nil?
        strain=Strain.new(:title=>strain_title,:organism_id=>organism.id)
        strain.save!
      end
    end
    self.culture_growth_type = culture_growth_type unless culture_growth_type.nil?
    self.strain=strain

  end
end
