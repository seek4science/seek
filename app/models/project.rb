require 'acts_as_editable'

class Project < ActiveRecord::Base
  
  acts_as_editable
  
  validates_presence_of :name
  validates_uniqueness_of :name
  
  validates_format_of :web_page, :with=>/(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix,:allow_nil=>true,:allow_blank=>true
  validates_format_of :wiki_page, :with=>/(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix,:allow_nil=>true,:allow_blank=>true
  
  validates_associated :avatars

  #TODO: refactor to remove :name entirely
  alias_attribute :title,:name
  
  has_many :avatars, 
           :as => :owner,
           :dependent => :destroy

  has_many :investigations
  has_many :studies, :through=>:investigations

  # can't destroy the assets, because these might be valuable even in the absence of the parent project
  has_many :assets, :dependent => :nullify
  
  # a default policy belonging to the project; this is set by a project PAL
  # if the project gets deleted, the default policy needs to be destroyed too
  # (no links to the default policy will be made from elsewhere; instead, when
  #  necessary, deep copies of it will be made to ensure that all settings get
  #  fully copied and assigned to belong to owners of assets, where identical policy
  #  is to be used)
  belongs_to :default_policy, 
             :class_name => 'Policy',
             :dependent => :destroy
  
  has_many :work_groups, :dependent=>:destroy
  has_many :institutions, :through=>:work_groups

  acts_as_taggable_on :organisms
  
  acts_as_solr(:fields => [ :name , :organisms]) if SOLR_ENABLED
  
  def institutions=(new_institutions)
    new_institutions.each_index do |i|
      new_institutions[i]=Institution.find(new_institutions[i]) unless new_institutions.is_a?(Institution)
    end
    work_groups.each do |wg|
      wg.destroy unless new_institutions.include?(wg.institution)
    end
    for institution in new_institutions
      institutions << institution unless institutions.include?(institution)
    end
  end
  
  def people
    res=[]
    work_groups.each do |wg|
      wg.people.each {|p| res << p unless res.include? p}
    end
    #TODO: write a test to check they are ordered
    return res.sort{|a,b| a.last_name <=> b.last_name}
  end
  
  # "false" returned by this helper method won't mean that no avatars are uploaded for this project;
  # it rather means that no avatar (other than default placeholder) was selected for the project 
  def avatar_selected?
    return !avatar_id.nil?
  end

  # provides a list of people that are said to be members of this project, but are not associated with any user
  def userless_people
    people.select{|p| p.user.nil?}
  end


  def includes_userless_people?
    peeps=people
    return peeps.size>0 && !(peeps.find{|p| p.user.nil?}).nil?
  end

  # Returns a list of projects that contain people that do not have users assigned to them
  def self.with_userless_people
    p=Project.find(:all, :include=>:work_groups)
    return p.select { |proj| proj.includes_userless_people? }
  end
  
  
  # get a listing of institutions for this project
  def get_institutions_listing
    workgroups_for_project = WorkGroup.find(:all, :conditions => {:project_id => self.id})
    return workgroups_for_project.collect { |w| [w.institution.name, w.institution.id, w.id] }
  end
  
end
