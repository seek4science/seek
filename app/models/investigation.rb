
class Investigation < ActiveRecord::Base    
  acts_as_isa

  belongs_to :project
  has_many :studies  


  validates_presence_of :project
  validates_uniqueness_of :title

  has_many :assays,:through=>:studies

  acts_as_solr(:fields=>[:description,:title]) if Seek::Config.solr_enabled

  def can_edit? user=User.current_user
    user == nil ? false : user.person.projects.include?(project)
  end

  def can_delete? user=nil
    studies.empty? && can_edit?(user)
  end
  
  def data_files
    assays.collect{|assay| assay.data_files}.flatten.uniq
  end
  
  def sops
    assays.collect{|assay| assay.sops}.flatten.uniq
  end

  
end
