require 'acts_as_isa'

class Investigation < ActiveRecord::Base    
  acts_as_isa

  #load the configuration for the pagination
  configpath=File.join(RAILS_ROOT,"config/paginate.yml")
  config=YAML::load_file(configpath)
  grouped_pagination :default_page => config["investigations"]["index"]

  belongs_to :project
  has_many :studies  


  validates_presence_of :project
  validates_uniqueness_of :title

  has_many :assays,:through=>:studies

  acts_as_solr(:fields=>[:description,:title]) if SOLR_ENABLED

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

  
end
