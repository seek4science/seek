require 'grouped_pagination'
require 'acts_as_authorized'
require "acts_as_scalable"
class Sample < ActiveRecord::Base
  include Subscribable

  acts_as_scalable

  belongs_to :specimen
  belongs_to :institution
  has_and_belongs_to_many :assays

  has_many :assets_creators, :dependent => :destroy, :as => :asset, :foreign_key => :asset_id
  has_many :creators, :class_name => "Person", :through => :assets_creators, :order=>'assets_creators.id'


  alias_attribute :description, :comments
  validates_presence_of :title
  validates_uniqueness_of :title
  validates_presence_of :specimen,:lab_internal_number
  validates_presence_of :donation_date



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

  acts_as_solr(:fields=>[:description,:title,:lab_internal_number],:include=>[:institution,:specimen,:assays]) if Seek::Config.solr_enabled

  acts_as_authorized


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
    return new_object
  end
end
