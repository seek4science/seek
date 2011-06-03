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
  alias_attribute :specimen_number, :donor_number

  validates_numericality_of :age, :only_integer => true, :greater_than=> 0, :allow_nil=> true, :message => "is not a positive integer"
  validates_presence_of :donor_number,:contributor,:lab_internal_number,:project,:institution,:organism

  validates_uniqueness_of :donor_number
  def self.sop_sql()
  'SELECT sop_versions.* FROM sop_versions ' +
  'INNER JOIN sop_specimens ' +
  'ON sop_specimens.sop_id = sop_versions.sop_id ' +
  'WHERE (sop_specimens.sop_version = sop_versions.version ' +
  'AND sop_specimens.specimen_id = #{self.id})'
  end

  has_many :sops,:class_name => "Sop::Version",:finder_sql => self.sop_sql()
  has_many :sop_masters,:class_name => "SopSpecimen"
  grouped_pagination :pages=>("A".."Z").to_a, :default_page => Seek::Config.default_page(self.name.underscore.pluralize)

  acts_as_solr(:fields=>[:description,:donor_number,:lab_internal_number],:include=>[:culture_growth_type,:organism,:strain]) if Seek::Config.solr_enabled

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


end
