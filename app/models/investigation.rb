
class Investigation < ActiveRecord::Base    
  acts_as_isa
  acts_as_authorized


  attr_accessor :new_link_from_study

  has_many :studies  


  validates_presence_of :projects
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
    new_object.policy = self.policy.deep_copy

    return new_object
  end

end
