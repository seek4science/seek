require 'grouped_pagination'

class Investigation < ActiveRecord::Base
  
  belongs_to :project
  has_many :studies  

  validates_presence_of :title
  validates_presence_of :project
  validates_uniqueness_of :title

  has_many :assays,:through=>:studies
  
  has_many :favourites, 
           :as => :resource, 
           :dependent => :destroy

  acts_as_solr(:fields=>[:description,:title]) if SOLR_ENABLED
  
  before_save :update_first_letter
  
  grouped_pagination  

  def can_edit? user
    user.person.projects.include?(project)
  end

  def can_delete? user
    studies.empty? && can_edit?(user)
  end
  
  def data_files
    assays.collect{|assay| assay.data_files}.flatten.uniq
  end
  
  def sops
    assays.collect{|assay| assay.sops}.flatten.uniq
  end
  
  def update_first_letter
    self.first_letter = strip_first_letter(title)
  end
  
end
