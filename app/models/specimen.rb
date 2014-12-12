require 'grouped_pagination'
require 'subscribable'

class Specimen < ActiveRecord::Base
  include Subscribable

  include Seek::Rdf::RdfGeneration
  include Seek::Biosamples::PhenoTypesAndGenoTypes
  include BackgroundReindexing
  include Seek::Stats::ActivityCounts

  acts_as_scalable if Seek::Config.is_virtualliver

  acts_as_authorized
  acts_as_favouritable
  acts_as_uniquely_identifiable

  grouped_pagination

  before_save  :clear_garbage

  attr_accessor :from_biosamples

  belongs_to :institution
  belongs_to :culture_growth_type
  belongs_to :strain

  has_one :organism, :through=>:strain

  has_many :samples
  has_many :treatments, :dependent=>:destroy
  has_many :activity_logs, :as => :activity_loggable
  has_many :assets_creators, :dependent => :destroy, :as => :asset, :foreign_key => :asset_id
  has_many :creators, :class_name => "Person", :through => :assets_creators, :order=>'assets_creators.id', :after_add => :update_timestamp, :after_remove => :update_timestamp
  has_many :sops,:class_name => "Sop::Version",:finder_sql => Proc.new{self.sop_sql()}
  has_many :sop_masters,:class_name => "SopSpecimen",:dependent => :destroy

  alias_attribute :description, :comments

  validates_numericality_of :age, :only_integer => true, :greater_than=> 0, :allow_nil=> true, :message => "is not a positive integer"
  validates_uniqueness_of :title

  validates_presence_of :title,:lab_internal_number, :contributor,:strain
  validates_presence_of :institution, :if => "Seek::Config.is_virtualliver"
  validates_presence_of :projects, :unless => Proc.new{|s| s.is_dummy? || Seek::Config.is_virtualliver}

  scope :default_order, order("title")

  HUMANIZED_COLUMNS = Seek::Config.is_virtualliver ? {} : {:born => 'culture starting date', :culture_growth_type => 'culture type'}
  HUMANIZED_COLUMNS[:title] = "#{(I18n.t 'biosamples.sample_parent_term').capitalize} title"
  HUMANIZED_COLUMNS[:lab_internal_number] = "#{(I18n.t 'biosamples.sample_parent_term').capitalize} lab internal identifier"
  HUMANIZED_COLUMNS[:provider_id] = "provider's #{(I18n.t 'biosamples.sample_parent_term')} identifier"


  AGE_UNITS = ["second","minute","hour","day","week","month","year"]

  def sop_sql()
  'SELECT sop_versions.* FROM sop_versions ' + 'INNER JOIN sop_specimens ' +
  'ON sop_specimens.sop_id = sop_versions.sop_id ' +
  'WHERE (sop_specimens.sop_version = sop_versions.version ' +
  "AND sop_specimens.specimen_id = #{self.id})"
  end

  include Seek::Search::BiosampleFields

  searchable(:auto_index=>false) do
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


  def build_sop_masters sop_ids
    # map string ids to int ids for ["1","2"].include? 1 == false
    sop_ids = sop_ids.map &:to_i
    sop_ids.each do |sop_id|
      if sop = Sop.find(sop_id)
        self.sop_masters.build :sop_id => sop.id, :sop_version => sop.version unless sop_masters.map(&:sop_id).include?(sop_id)
      end
    end
    self.sop_masters = self.sop_masters.select { |s| sop_ids.include? s.sop_id }
  end



  def related_people
    creators
  end

  def related_sops
    sop_masters.collect(&:sop)
  end
  

  def age_with_unit
      age.nil? ? "" : "#{age}(#{age_unit}s)"
  end

  def state_allows_delete? user=User.current_user
    samples.empty? && super
  end

  def self.user_creatable?
    Seek::Config.biosamples_enabled
  end

  def clear_garbage
    if culture_growth_type.try(:title)=="in vivo"
      self.medium=nil
      self.culture_format=nil
      self.temperature=nil
      self.ph=nil
      self.confluency=nil
      self.passage=nil
      self.viability=nil
      self.purity=nil
    end
    if culture_growth_type.try(:title)=="cultured cell line"||culture_growth_type.try(:title)=="primary cell culture"
      self.sex=nil
      self.born=nil
      self.age=nil
    end
  end

  def strain_title
    self.strain.try(:title)
  end

  def strain_title= title
    existing = Strain.all.select{|s|s.title==title}.first
    if existing.blank?
      self.strain = Strain.create(:title=>title)
    else
      self.strain= existing
    end
  end

  def clone_with_associations
    new_object= self.dup
    new_object.policy = self.policy.deep_copy
    new_object.sop_masters = self.try(:sop_masters)
    new_object.creators = self.try(:creators)
    new_object.project_ids = self.project_ids
    new_object.genotypes = self.genotypes.map &:clone
    new_object.phenotypes = self.phenotypes.map &:clone
    return new_object
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
