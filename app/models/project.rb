require 'grouped_pagination'
require 'simple_crypt'
require 'title_trimmer'

class Project < ActiveRecord::Base

  include Seek::Rdf::RdfGeneration

  acts_as_yellow_pages 

  include SimpleCrypt

  title_trimmer

  default_scope :order => "#{self.table_name}.name"
  validates_uniqueness_of :name

  validates_format_of :web_page, :with=>/(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix,:allow_nil=>true,:allow_blank=>true
  validates_format_of :wiki_page, :with=>/(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix,:allow_nil=>true,:allow_blank=>true

  has_and_belongs_to_many :investigations

  has_and_belongs_to_many :data_files
  has_and_belongs_to_many :models
  has_and_belongs_to_many :sops
  has_and_belongs_to_many :publications
  has_and_belongs_to_many :events
  has_and_belongs_to_many :presentations

  def studies
    investigations.collect(&:studies).flatten.uniq
  end
    
  # a default policy belonging to the project; this is set by a project PAL
  # if the project gets deleted, the default policy needs to be destroyed too
  # (no links to the default policy will be made from elsewhere; instead, when
  #  necessary, deep copies of it will be made to ensure that all settings get
  #  fully copied and assigned to belong to owners of assets, where identical policy
  #  is to be used)
  belongs_to :default_policy, 
    :class_name => 'Policy',
    :dependent => :destroy,
    :autosave => true

  after_initialize :default_default_policy_if_new

  def default_default_policy_if_new
    self.default_policy = Policy.default if new_record?
  end

  has_many :work_groups, :dependent=>:destroy
  has_many :institutions, :through=>:work_groups
  
  alias_attribute :webpage, :web_page
  alias_attribute :internal_webpage, :wiki_page

  has_and_belongs_to_many :organisms
  has_many :project_subscriptions,:dependent => :destroy
  
  searchable(:ignore_attribute_changes_of=>[:updated_at]) do
    text :name , :description, :locations
  end if Seek::Config.solr_enabled

  attr_accessor :site_username,:site_password

  before_save :set_credentials

  def assets
    data_files | sops | models | publications | presentations
  end
  
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

  #this is the intersection of project role and seek role
  def pals
    pal_role=ProjectRole.pal_role
    people.select{|p| p.is_pal?}.select do |possible_pal|
      possible_pal.project_roles_of_project(self).include?(pal_role)
    end
  end

  #this is project role
  def pis
    pi_role = ProjectRole.find_by_name('PI')
    people.select{|p| p.project_roles_of_project(self).include?(pi_role)}
  end

  #this is seek role
  def asset_managers
    people.select(&:is_asset_manager?)
  end

  #this is seek role
  def project_managers
    people.select(&:is_project_manager?)
  end

  #this is seek role
  def gatekeepers
    people.select(&:is_gatekeeper?)
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
    #TODO: look into doing this with a scope or direct query
    res = work_groups.collect(&:people).flatten.uniq.compact
    #TODO: write a test to check they are ordered
    res.sort_by{|a| (a.last_name.blank? ? a.name : a.last_name)}
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
    p=Project.all(:include=>:work_groups)
    return p.select { |proj| proj.includes_userless_people? }
  end
  
  
  # get a listing of institutions for this project
  def get_institutions_listing
    workgroups_for_project = WorkGroup.where(:project_id => self.id)
    return workgroups_for_project.collect { |w| [w.institution.name, w.institution.id, w.id] }
  end

  def assays
    studies.collect{|s| s.assays}.flatten.uniq
  end

  def set_credentials
    unless site_username.nil? && site_password.nil?
      cred={:username=>site_username,:password=>site_password}
      cred=encrypt(cred,generate_key(GLOBAL_PASSPHRASE))
      self.site_credentials=Base64.encode64(cred).encode('utf-8')
    end
  end

  def decrypt_credentials
    begin
      decoded = Base64.decode64 site_credentials
      cred=decrypt(decoded,generate_key(GLOBAL_PASSPHRASE))
      self.site_password=cred[:password]
      self.site_username=cred[:username]
    rescue
      
    end
  end

  #indicates whether this project has a person, or associated user, as a member
  def has_member? user_or_person
    user_or_person = user_or_person.try(:person) if user_or_person.is_a?(User)
    self.people.include? user_or_person
  end

  def person_roles(person)
    #Get intersection of all project memberships + person's memberships to find project membership
    project_memberships = work_groups.collect{|w| w.group_memberships}.flatten
    person_project_membership = person.group_memberships & project_memberships
    return person_project_membership.project_roles
  end

  def can_be_edited_by?(user)
    user == nil ? false : (user.is_admin? || (self.has_member?(user) && (user.can_edit_projects? || user.is_project_manager?)))
  end

  def can_be_administered_by?(user)
    user == nil ? false : (user.is_admin? || (self.has_member?(user) && (user.is_project_manager?)))
  end

end
