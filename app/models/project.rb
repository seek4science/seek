require 'grouped_pagination'
require 'simple_crypt'
require 'title_trimmer'

class Project < ActiveRecord::Base

  acts_as_yellow_pages

  include SimpleCrypt
  include ActsAsCachedTree

  after_update :touch_for_hierarchy_updates

  def touch_for_hierarchy_updates
    if changed_attributes.include? :parent_id
      Permission.find_by_contributor_type("Project", :conditions => {:contributor_id => ([id] + ancestors.map(&:id) + descendants.map(&:id))}).each &:touch
      ancestors.each &:touch
      descendants.each &:touch
    end
  end

  #when I have a new ancestor, subscribe to items in that project
  write_inheritable_array :before_add_for_ancestors, [:add_indirect_subscriptions]

  has_many :project_subscriptions

  def add_indirect_subscriptions ancestor
    subscribers = project_subscriptions.scoped(:include => :person).map(&:person)
    possibly_new_items = ancestor.subscribable_items #might already have subscriptions to these some other way
    subscribers.each do |p|
      possibly_new_items.each {|i| i.subscribe(p); disable_authorization_checks{i.save(false)} if i.changed_for_autosave?}
    end
  end

  def subscribable_items
    #TODO: Possibly refactor this. Probably the Project#subscribable_items should only return the subscribable items directly in _this_ project, not including its ancestors
    ProjectSubscription.subscribable_types.collect {|klass|
      if klass.reflect_on_association(:projects)
        then klass.scoped(:include => :projects)
      else
        klass.all
      end}.flatten.select {|item| !(([self] + ancestors) & item.projects).empty?}
  end

  title_trimmer
  
  validates_uniqueness_of :name

  grouped_pagination :pages=>("A".."Z").to_a, :default_page => Seek::Config.default_page(self.name.underscore.pluralize) #shouldn't need "Other" tab for project
  

  validates_format_of :web_page, :with=>/(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix,:allow_nil=>true,:allow_blank=>true
  validates_format_of :wiki_page, :with=>/(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix,:allow_nil=>true,:allow_blank=>true

  has_and_belongs_to_many :investigations

  has_and_belongs_to_many :data_files
  has_and_belongs_to_many :models
  has_and_belongs_to_many :sops
  has_and_belongs_to_many :publications
  has_and_belongs_to_many :events
  has_and_belongs_to_many :presentations

  RELATED_RESOURCE_TYPES = ["Investigation","Study","Assay","DataFile","Model","Sop","Publication","Event","Presentation","Organism"]

  RELATED_RESOURCE_TYPES.each do |type|
     define_method "related_#{type.underscore.pluralize}" do
         res = send "#{type.underscore.pluralize}"
         descendants.each do |descendant|
           res = res | descendant.send("#{type.underscore.pluralize}")
         end
          res.compact
     end
  end


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
    self.default_policy = Policy.private_policy if new_record?
  end

  has_many :work_groups, :dependent=>:destroy
  has_many :institutions, :through=>:work_groups, :after_add => :create_ancestor_workgroups, :before_remove => :check_workgroup_is_empty

  def create_ancestor_workgroups institution
    parent.institutions << institution unless parent.nil? || parent.institutions.include?(institution)
  end

  def check_workgroup_is_empty institution
    raise unless work_groups.find_by_institution(institution).people.empty?
  end

  alias_attribute :webpage, :web_page
  alias_attribute :internal_webpage, :wiki_page

  has_and_belongs_to_many :organisms  
  
  searchable(:ignore_attribute_changes_of=>[:updated_at]) do
    text :name , :description, :locations
  end if Seek::Config.solr_enabled

  attr_accessor :site_username,:site_password

  before_save :set_credentials

  def project_coordinators
    coordinator_role = ProjectRole.project_coordinator_role
    people.select{|p| p.project_roles_of_project(self).include?(coordinator_role)} | descendants.collect(&:project_coordinators).flatten
  end

  #this is the intersection of project role and seek role
  def pals
    pal_role=ProjectRole.pal_role
    people.select{|p| p.is_pal?}.select do |possible_pal|
      possible_pal.project_roles_of_project(self).include?(pal_role)
    end | descendants.collect(&:pals).flatten
  end

  #this is project role
  def pis
    pi_role = ProjectRole.find_by_name('PI')
    people.select{|p| p.project_roles_of_project(self).include?(pi_role)} | descendants.collect(&:pis).flatten
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
  def publishers
    people.select(&:is_publisher?)
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
    res = work_groups.collect(&:people)
    res = res + descendants.collect(&:people)

    #TODO: write a test to check they are ordered
    res = res.flatten.uniq.compact
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
    p=Project.find(:all, :include=>:work_groups)
    return p.select { |proj| proj.includes_userless_people? }
  end
  
  
  # get a listing of institutions for this project
  def get_institutions_listing
    workgroups_for_project = WorkGroup.find(:all, :conditions => {:project_id => self.id})
    return workgroups_for_project.collect { |w| [w.institution.name, w.institution.id, w.id] }
  end

  def assays
    studies.collect{|s| s.assays}.flatten.uniq
  end

  def set_credentials
    unless site_username.nil? && site_password.nil?
      cred={:username=>site_username,:password=>site_password}
      self.site_credentials=encrypt(cred,generate_key(GLOBAL_PASSPHRASE))
    end
  end

  def decrypt_credentials
    begin
      cred=decrypt(site_credentials,generate_key(GLOBAL_PASSPHRASE))
      self.site_password=cred[:password]
      self.site_username=cred[:username]
    rescue
      
    end
  end
  
  def person_roles(person)
    #Get intersection of all project memberships + person's memberships to find project membership
    project_memberships = work_groups.collect{|w| w.group_memberships}.flatten
    person_project_membership = person.group_memberships & project_memberships
    return person_project_membership.project_roles
  end

  def can_be_edited_by?(subject)
    subject == nil ? false : (subject.is_admin? || (self.people.include?(subject.person) && (subject.can_edit_projects? || subject.is_project_manager?)))
  end

  def can_be_administered_by?(subject)
    subject == nil ? false : (subject.is_admin? || (self.people.include?(subject.person) && (subject.is_project_manager?)))
  end

end
