require 'grouped_pagination'
require 'subscribable'

class DeprecatedSpecimen < ActiveRecord::Base
  include Seek::Subscribable

  include Seek::Rdf::RdfGeneration
  include Seek::Biosamples::PhenoTypesAndGenoTypes
  include Seek::Search::BackgroundReindexing
  include Seek::Stats::ActivityCounts

  acts_as_scalable if Seek::Config.is_virtualliver

  acts_as_authorized
  acts_as_favouritable
  acts_as_uniquely_identifiable

  grouped_pagination

  before_save :clear_garbage

  belongs_to :institution
  belongs_to :culture_growth_type
  belongs_to :strain

  has_one :organism, through: :strain

  has_many :activity_logs, as: :activity_loggable
  has_many :assets_creators, dependent: :destroy, as: :asset, foreign_key: :asset_id
  has_many :creators, class_name: 'Person', through: :assets_creators, order: 'assets_creators.id', after_add: :update_timestamp, after_remove: :update_timestamp
  has_many :sop_versions, class_name: 'Sop::Version', finder_sql: proc { sop_sql }

  alias_attribute :description, :comments

  validates_numericality_of :age, only_integer: true, greater_than: 0, allow_nil: true, message: 'is not a positive integer'
  validates_uniqueness_of :title

  validates_presence_of :title, :lab_internal_number, :contributor, :strain
  validates_presence_of :institution, if: 'Seek::Config.is_virtualliver'
  validates_presence_of :projects, unless: proc { |s| s.is_dummy? || Seek::Config.is_virtualliver }

  scope :default_order, order('title')

  # DEPRECATED
  has_many :deprecated_samples
  has_many :deprecated_treatments, dependent: :destroy
  has_many :sop_specimens, dependent: :destroy
  has_many :sops, through: :sop_specimens

  HUMANIZED_COLUMNS = Seek::Config.is_virtualliver ? {} : { born: 'culture starting date', culture_growth_type: 'culture type' }
  HUMANIZED_COLUMNS[:title] = "#{(I18n.t 'biosamples.sample_parent_term').capitalize} title"
  HUMANIZED_COLUMNS[:lab_internal_number] = "#{(I18n.t 'biosamples.sample_parent_term').capitalize} lab internal identifier"
  HUMANIZED_COLUMNS[:provider_id] = "provider's #{(I18n.t 'biosamples.sample_parent_term')} identifier"

  AGE_UNITS = %w(second minute hour day week month year)

  def sop_sql
    'SELECT sop_versions.* FROM sop_versions ' + 'INNER JOIN sop_specimens ' \
    'ON sop_deprecated_specimens.sop_id = sop_versions.sop_id ' \
    'WHERE (sop_deprecated_specimens.sop_version = sop_versions.version ' \
    "AND sop_deprecated_specimens.deprecated_specimen_id = #{id})"
  end

  searchable(auto_index: false) do
    text :other_creators
    text :culture_growth_type do
      culture_growth_type.try :title
    end

    text :strain do
      strain.try :title
      strain.try(:organism).try(:title).to_s
    end

    text :creators do
      creators.compact.map(&:name)
    end
  end if Seek::Config.solr_enabled

  def self.authorization_supported?
    false
  end

  def build_sops(sop_ids)
    # map string ids to int ids for ["1","2"].include? 1 == false
    sop_ids = sop_ids.map &:to_i
    sop_ids.each do |sop_id|
      if sop = Sop.find(sop_id)
        sop_deprecated_specimens.build sop_id: sop.id, sop_version: sop.version unless sops.map(&:id).include?(sop_id)
      end
    end
    self.sop_deprecated_specimens = sop_deprecated_specimens.select { |s| sop_ids.include? s.sop_id }
  end

  def related_people
    creators
  end

  def age_with_unit
    age.nil? ? '' : "#{age}(#{age_unit}s)"
  end

  def state_allows_delete?(user = User.current_user)
    deprecated_samples.empty? && super
  end

  def clear_garbage
    if culture_growth_type.try(:title) == 'in vivo'
      self.medium = nil
      self.culture_format = nil
      self.temperature = nil
      self.ph = nil
      self.confluency = nil
      self.passage = nil
      self.viability = nil
      self.purity = nil
    end
    if culture_growth_type.try(:title) == 'cultured cell line' || culture_growth_type.try(:title) == 'primary cell culture'
      self.sex = nil
      self.born = nil
      self.age = nil
    end
  end

  def strain_title
    strain.try(:title)
  end

  def strain_title=(title)
    existing = Strain.all.find { |s| s.title == title }
    if existing.blank?
      self.strain = Strain.create(title: title)
    else
      self.strain = existing
    end
  end

  def clone_with_associations
    new_object = dup
    new_object.policy = policy.deep_copy
    new_object.sops = try(:sops)
    new_object.creators = try(:creators)
    new_object.project_ids = project_ids
    new_object.genotypes = genotypes.map &:clone
    new_object.phenotypes = phenotypes.map &:clone
    new_object
  end

  def self.human_attribute_name(attribute, options = {})
    HUMANIZED_COLUMNS[attribute.to_sym] || super
  end

  def born_info
    if born.nil?
      ''
    else
      if try(:born).hour == 0 && try(:born).min == 0 && try(:born).sec == 0
        try(:born).strftime('%d/%m/%Y')
      else
        try(:born).strftime('%d/%m/%Y @ %H:%M:%S')
      end
    end
  end

  def organism
    strain.try(:organism)
  end
end
