require 'grouped_pagination'
require 'acts_as_authorized'

class Sample < ActiveRecord::Base
  include Subscribable

  acts_as_authorized
  acts_as_favouritable

  attr_accessor :from_new_link
  attr_accessor :from_biosamples

  belongs_to :specimen

  accepts_nested_attributes_for :specimen

  belongs_to :institution
  has_and_belongs_to_many :assays

  has_many :assets_creators, :dependent => :destroy, :as => :asset, :foreign_key => :asset_id
  has_many :creators, :class_name => "Person", :through => :assets_creators, :order=>'assets_creators.id'

  alias_attribute :description, :comments
  validates_presence_of :title
  validates_uniqueness_of :title
  validates_presence_of :specimen,:lab_internal_number, :projects
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

  HUMANIZED_COLUMNS = {:title => "Sample name", :lab_internal_number=> "Sample lab internal identifier", :provider_id => "Provider's sample identifier"}

  searchable do
    text :searchable_terms
  end if Seek::Config.solr_enabled


  def searchable_terms
    text=[]
    text << title
    text << description
    text << lab_internal_number
    text << provider_name
    text << provider_id
    if (specimen)
      text << specimen.lab_internal_number
      text << specimen.provider_id
      text << specimen.title
      text << specimen.provider_id
      if (specimen.strain)
        text << specimen.try(:strain).try(:info).to_s
        text << specimen.try(:strain).try(:organism).try(:title).to_s
      end
    end
    text
  end

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

  def self.human_attribute_name(attribute)
    HUMANIZED_COLUMNS[attribute.to_sym] || super
  end

  def sampling_date_info
    if sampling_date.nil?
      ''
    else
      if try(:sampling_date).hour == 0 and try(:sampling_date).min == 0 and try(:sampling_date).sec == 0 then
        try(:sampling_date).strftime('%d/%m/%Y')
      else
        try(:sampling_date).strftime('%d/%m/%Y @ %H:%M:%S')
      end

    end
  end

  def provider_name_info
    provider_name.blank? ? contributor.try(:person).try(:name) : provider_name
  end

  def specimen_info
    specimen.nil? ? '' : CELL_CULTURE_OR_SPECIMEN.capitalize + ' ' + specimen.title
  end
end
