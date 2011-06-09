
class Investigation < ActiveRecord::Base    
  acts_as_isa
  acts_as_authorized

  has_many :studies  


  validates_presence_of :project
  validates_uniqueness_of :title

  has_many :assays,:through=>:studies

  acts_as_solr(:fields=>[:description,:title]) if Seek::Config.solr_enabled

  def can_delete? *args
    studies.empty? && super
  end
  
  def data_files
    assays.collect{|assay| assay.data_files}.flatten.uniq
  end
  
  def sops
    assays.collect{|assay| assay.sops}.flatten.uniq
  end

  def clone_with_associations
    new_object= self.clone
    new_object.policy = Policy.find self.policy_id
    new_object.policy.permission_ids = self.policy.permission_ids

    return new_object
  end

end
