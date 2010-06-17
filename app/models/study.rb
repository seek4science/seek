require 'grouped_pagination'
require 'acts_as_uniquely_identifiable'

class Study < ActiveRecord::Base  
 
  belongs_to :investigation
  
  has_many :assays
  
  has_one :project, :through=>:investigation

  #has_many :data_files,:through=>:assays
  
  belongs_to :person_responsible, :class_name => "Person"
  
  has_many :favourites, 
           :as => :resource, 
           :dependent => :destroy

  validates_presence_of :title
  validates_presence_of :investigation

  validates_uniqueness_of :title

  acts_as_solr(:fields=>[:description,:title]) if SOLR_ENABLED
  
  before_save :update_first_letter
  
  grouped_pagination
  
  acts_as_uniquely_identifiable

  def sops    
    assays.collect{|assay| assay.sops.collect{|sop| sop}}.flatten.uniq    
  end

  def can_edit? user
    user.person && user.person.projects.include?(project)
  end

  def can_delete? user
    assays.empty? && can_edit?(user)
  end
  
  def data_files
    assays.collect{|assay| assay.data_files.collect{|df| df  }}.flatten.uniq
  end
  
  def update_first_letter
    self.first_letter = strip_first_letter(title)
  end

end
