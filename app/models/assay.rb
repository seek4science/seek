require 'grouped_pagination'

class Assay < ActiveRecord::Base    
  
  belongs_to :assay_type
  belongs_to :technology_type
  belongs_to :culture_growth_type
  belongs_to :study
  belongs_to :organism
  belongs_to :owner, :class_name=>"Person"
  belongs_to :assay_class

  has_many :assay_assets, :dependent => :destroy

  has_one :investigation,:through=>:study    

  has_many :assets,:through=>:assay_assets

  validates_presence_of :title
  validates_uniqueness_of :title

  validates_presence_of :assay_type
  validates_presence_of :technology_type
  validates_presence_of :study, :message=>" must be selected"
  validates_presence_of :owner

  has_many :favourites, 
           :as => :resource, 
           :dependent => :destroy
           


  acts_as_solr(:fields=>[:description,:title],:include=>[:assay_type,:technology_type,:organism]) if SOLR_ENABLED
  
  before_save :update_first_letter
  
  grouped_pagination
  
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

  def sops
    assay_assets.sops.collect{|s| s.versioned_resource}
  end

  def data_files
    assay_assets.data_files.collect{|df| df.versioned_resource}
  end
  
  def update_first_letter
    self.first_letter = strip_first_letter(title)
  end
  
end
