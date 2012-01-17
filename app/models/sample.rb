require 'grouped_pagination'
require 'acts_as_authorized'

class Sample < ActiveRecord::Base
  include Subscribable

  acts_as_authorized
  acts_as_favouritable

  attr_accessor :from_new_link

  belongs_to :specimen

  accepts_nested_attributes_for :specimen

  belongs_to :institution
  has_and_belongs_to_many :assays

  has_many :assets_creators, :dependent => :destroy, :as => :asset, :foreign_key => :asset_id
  has_many :creators, :class_name => "Person", :through => :assets_creators, :order=>'assets_creators.id'

  alias_attribute :description, :comments
  validates_presence_of :title
  validates_uniqueness_of :title
  validates_presence_of :specimen,:lab_internal_number
  validates_presence_of :donation_date if Seek::Config.is_virtualliver

  validates_numericality_of :age_at_sampling, :only_integer => true, :greater_than=> 0, :allow_nil=> true, :message => "is not a positive integer" if !Seek::Config.is_virtualliver

  def self.sop_sql()
  'SELECT sop_versions.* FROM sop_versions ' +
  'INNER JOIN sample_sops ' +
  'ON sample_sops.sop_id = sop_versions.sop_id ' +
  'WHERE (sample_sops.sop_version = sop_versions.version ' +
  'AND sample_sops.sample_id = #{self.id})'
  end

  has_many :sops, :class_name => "Sop::Version", :finder_sql => self.sop_sql()
  has_many :sop_masters,:class_name => "SampleSop"
  grouped_pagination :pages=>("A".."Z").to_a, :default_page => Seek::Config.default_page(self.name.underscore.pluralize)


  searchable do
    text :description,:title,:lab_internal_number
    text :assays do
      assays.map{|a| a.title}
    end
    text :specimen do
      specimen.try :title
    end
  end if Seek::Config.solr_enabled

  def can_delete? *args
    assays.empty? && super
  end

  def self.user_creatable?
    true
  end

  def associate_sop sop
    sample_sop = sop_masters.detect{|ss|ss.sop==sop}

    if sample_sop.nil?
      sample_sop = SampleSop.new
      sample_sop.sample = self
    end
    sample_sop.sop = sop
    sample_sop.sop_version = sop.version
    sample_sop.save if sample_sop.changed?

    return sample_sop
  end

  def clone_with_associations
    new_object= self.clone
    new_object.policy = self.policy.deep_copy
    new_object.sop_masters = self.try(:sop_masters)
    new_object.project_ids = self.project_ids
    return new_object
  end
end
