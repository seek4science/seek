require 'acts_as_editable'
require 'grouped_pagination'
require 'simple_crypt'

class Project < ActiveRecord::Base

  include SimpleCrypt
  
  acts_as_editable
  
  has_many :favourites, 
           :as => :resource, 
           :dependent => :destroy
  
  validates_presence_of :name
  validates_uniqueness_of :name

  before_save :update_first_letter

  grouped_pagination
  
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

  has_and_belongs_to_many :organisms  
  
  acts_as_solr(:fields => [ :name , :description, :locations],:include=>[:organisms]) if SOLR_ENABLED

  attr_accessor :site_username,:site_password

  before_save :set_credentials
  
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

  def pals
    #TODO: look into doing this with a named_scope or direct query
    people.select{|p| p.is_pal?}
  end

  def locations
    # infer all project's locations from the institutions where the person is member of
    locations = self.institutions.collect { |i| i.country unless i.country.blank? }

    # make sure this list is unique and (if any institutions didn't have a country set) that 'nil' element is deleted
    locations = locations.uniq
    locations.delete(nil)

    return locations
  end
  
  def people
    #TODO: look into doing this with a named_scope or direct query
    res=[]
    work_groups.each do |wg|
      wg.people.each {|p| res << p unless res.include? p}
    end
    #TODO: write a test to check they are ordered
    return res.sort{|a,b| (a.last_name.nil? ? a.name : a.last_name) <=> (a.last_name.nil? ? a.name : a.last_name)}
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

  def update_first_letter
    self.first_letter=strip_first_letter(name)
  end

  def assays
    studies.collect{|s| s.assays}.flatten.uniq
  end

  def set_credentials
    cred={:username=>site_username,:password=>site_password}
    self.site_credentials=encrypt(cred,generate_key(GLOBAL_PASSPHRASE))
  end

  def decrypt_credentials
    cred=decrypt(site_credentials,generate_key(GLOBAL_PASSPHRASE))
    self.site_password=cred[:password]
    self.site_username=cred[:username]
  end
end
