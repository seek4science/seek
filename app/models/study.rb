require 'acts_as_isa'

class Study < ActiveRecord::Base  
  acts_as_isa

  #load the configuration for the pagination
=begin
  configpath=File.join(RAILS_ROOT,"config/paginate.yml")
  config=YAML::load_file(configpath)
  grouped_pagination :default_page => config["studies"]["index"]
=end
  grouped_pagination :default_page => Settings.index[:studies]
  belongs_to :investigation
  
  has_many :assays
  
  has_one :project, :through=>:investigation

  belongs_to :person_responsible, :class_name => "Person"


  validates_presence_of :investigation

  validates_uniqueness_of :title

  acts_as_solr(:fields=>[:description,:title]) if SOLR_ENABLED

  def data_files
    assays.collect{|a| a.data_files}.flatten.uniq
  end
  
  def sops
    assays.collect{|a| a.sops}.flatten.uniq
  end 

  def can_edit? user
    user.person && user.person.projects.include?(project)
  end

  def can_delete? user
    assays.empty? && can_edit?(user)
  end


end
