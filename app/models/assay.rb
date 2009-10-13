class Assay < ActiveRecord::Base  
  
  has_and_belongs_to_many :sops
  
  belongs_to :assay_type
  belongs_to :technology_type
  belongs_to :culture_growth_type
  belongs_to :study
  belongs_to :organism
  belongs_to :owner, :class_name=>"Person"

  has_many :assay_assets

  has_one :investigation,:through=>:study  

  has_many :created_datas
  has_many :data_files,:through=>:created_datas

  has_many :assets,:through=>:assay_assets

  

  validates_presence_of :title
  validates_uniqueness_of :title

  validates_presence_of :assay_type
  validates_presence_of :technology_type
  validates_presence_of :study, :message=>" must be selected"
  validates_presence_of :owner

  acts_as_solr(:fields=>[:description,:title],:include=>[:assay_type,:technology_type,:organism]) if SOLR_ENABLED
  
  def short_description
    type=assay_type.nil? ? "No type" : assay_type.title
   
    "#{title} (#{type})"
  end

  def project
    investigation.nil? ? nil : investigation.project
  end

  def can_edit? user
    project.nil? || user.person.projects.include?(project)
  end

  def can_delete? user
    can_edit?(user) && data_files.empty? && sops.empty?
  end

  def versioned_sops
    assay_assets.sops.collect{|s| s.versioned_resource}
  end
  
end
