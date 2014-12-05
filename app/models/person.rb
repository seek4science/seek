require 'grouped_pagination'

class Person < ActiveRecord::Base

  include Seek::Rdf::RdfGeneration
  include Seek::Taggable
  include Seek::AdminDefinedRoles

  alias_attribute :title, :name

  acts_as_yellow_pages
  scope :default_order, order("last_name, first_name")

  before_save :first_person_admin
  before_destroy :clean_up_and_assign_permissions

  acts_as_notifiee
  acts_as_annotatable :name_field=>:name

  validates_presence_of :email

  #FIXME: consolidate these regular expressions into 1 holding class
  validates_format_of :email,:with => RFC822::EMAIL
  validates_format_of :web_page, :with=>/(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix,:allow_nil=>true,:allow_blank=>true

  validates_uniqueness_of :email,:case_sensitive => false

  has_and_belongs_to_many :disciplines

  has_many :group_memberships, :dependent => :destroy
  has_many :work_groups, :through=>:group_memberships
  has_many :institutions,:through => :work_groups, :uniq => true

  has_many :favourite_group_memberships, :dependent => :destroy
  has_many :favourite_groups, :through => :favourite_group_memberships


  has_many :studies_for_person, :as=>:contributor, :class_name=>"Study"  
  has_many :assays,:foreign_key => :owner_id
  has_many :investigations_for_person,:as=>:contributor, :class_name=>"Investigation"
  has_many :presentations_for_person,:as=>:contributor, :class_name=>"Presentation"

  validate :orcid_id_must_be_valid_or_blank

  has_one :user, :dependent=>:destroy

  has_many :assets_creators, :dependent => :destroy, :foreign_key => "creator_id"
  has_many :created_data_files, :through => :assets_creators, :source => :asset, :source_type => "DataFile"
  has_many :created_models, :through => :assets_creators, :source => :asset, :source_type => "Model"
  has_many :created_sops, :through => :assets_creators, :source => :asset, :source_type => "Sop"
  has_many :created_publications, :through => :assets_creators, :source => :asset, :source_type => "Publication"
  has_many :created_presentations,:through => :assets_creators,:source=>:asset,:source_type => "Presentation"

  searchable(:auto_index => false) do
    text :project_roles
    text :disciplines do
      disciplines.map{|d| d.title}
    end
  end if Seek::Config.solr_enabled

  scope :with_group, :include=>:group_memberships, :conditions=>"group_memberships.person_id IS NOT NULL"
  scope :without_group, :include=>:group_memberships, :conditions=>"group_memberships.person_id IS NULL"
  scope :registered,:include=>:user,:conditions=>"users.person_id != 0"

  scope :not_registered,:include=>:user,:conditions=>"users.person_id IS NULL"

  alias_attribute :webpage,:web_page

  include Seek::Subscriptions::PersonProjectSubscriptions

  after_commit :queue_update_auth_table

  def queue_update_auth_table
    if previous_changes.keys.include?("roles_mask")
      AuthLookupUpdateJob.add_items_to_queue self
    end
  end

  def guest_project_member?
    project = Project.find_by_title('BioVeL Portal Guests')
    !project.nil? && self.projects == [project]
  end

  #those that have updated time stamps and avatars appear first. A future enhancement could be to judge activity by last asset updated timestamp
  def self.active
    Person.unscoped.order("avatar_id is null, updated_at DESC")
  end

  def receive_notifications
    member? and super
  end

  def registered?
    !user.nil?
  end

  def person
    self
  end

  def email_uri
    URI.escape("mailto:"+email)
  end

  def studies
    result = studies_for_person
    if user
      result = (result | user.studies).compact
    end
    result.uniq
  end

  def investigations
    result = investigations_for_person
    if user
      result = (result | user.investigations).compact
    end
    result.uniq
  end

  def presentations
    result = presentations_for_person
    if user
      result = (result | user.investigations).compact
    end
    result.uniq
  end

  def related_samples
    user_items = []
    user_items =  user.try(:send,:samples) if user.respond_to?(:samples)
    user_items
  end

  def programmes
    self.projects.collect{|p| p.programme}.uniq
  end


  RELATED_RESOURCE_TYPES = [:data_files,:models,:sops,:presentations,:events,:publications, :investigations]
  RELATED_RESOURCE_TYPES.each do |type|
    define_method "related_#{type}" do
      user_items = []
      user_items =  user.try(:send,type) if user.respond_to?(type) && [:events,:investigations].include?(type)
      user_items =  user_items | self.send("created_#{type}".to_sym) if self.respond_to? "created_#{type}".to_sym
      user_items = user_items | self.send("#{type}_for_person".to_sym) if self.respond_to? "#{type}_for_person".to_sym
      user_items.uniq
    end
  end

  #returns an array of Person's where the first and last name match
  def self.duplicates
    people=Person.all
    dup=[]
    people.each do |p|
      peeps=people.select{|p2| p.name==p2.name}
      dup = dup | peeps if peeps.count>1
    end
    return dup
  end

  # get a list of people with their email for autocomplete fields
  def self.get_all_as_json
    Person.order("ID asc").collect do |p|
      {"id" => p.id,"name" => p.name,"email" => p.email}
    end.to_json
  end

  def validates_associated(*associations)
    associations.each do |association|
      class_eval do
        validates_each(associations) do |record, associate_name, value|
          associates = record.send(associate_name)
          associates = [associates] unless associates.respond_to?('each')
          associates.each do |associate|
            if associate && !associate.valid?
              associate.errors.each do |key, value|
                record.errors.add(key, value)
              end
            end
          end
        end
      end
    end
  end

  def can_create_new_items?
    member?
  end

  def workflows
     self.try(:user).try(:workflows) || []
  end

  def runs
    self.try(:user).try(:taverna_player_runs) || []
  end

  def sweeps
    self.try(:user).try(:sweeps) || []
  end

  def projects
      #updating workgroups doesn't change groupmemberships until you save. And vice versa.
      work_groups.collect {|wg| wg.project }.uniq | group_memberships.collect{|gm| gm.work_group.project}
  end

  def member?
    !projects.empty?
  end

  def member_of?(item_or_array)
    !(Array(item_or_array) & projects).empty?
  end

  def locations
    # infer all person's locations from the institutions where the person is member of
    self.institutions.collect(&:country).compact.uniq
  end

  def email_with_name
    name + " <" + email + ">"
  end

  def name
    firstname=first_name || ""
    lastname=last_name || ""
    #capitalize, including double barrelled names
    #TODO: why not just store them like this rather than processing each time? Will need to reprocess exiting entries if we do this.
    return (firstname.gsub(/\b\w/) {|s| s.upcase} + " " + lastname.gsub(/\b\w/) {|s| s.upcase}).strip
  end

  #returns true this is an admin person, and they are the only one defined - indicating they are person creating during setting up SEEK
  def only_first_admin_person?
    Person.count==1 && [self]==Person.all && Person.first.is_admin?
  end

  #the roles defined within the project
  def project_roles
    project_roles = []
    group_memberships.each do |gm|
      project_roles = project_roles | gm.project_roles
    end
    project_roles
  end

  def update_first_letter
    no_last_name=last_name.nil? || last_name.strip.blank?
    first_letter = strip_first_letter(last_name) unless no_last_name
    first_letter = strip_first_letter(name) if no_last_name
    #first_letter = "Other" unless ("A".."Z").to_a.include?(first_letter)
    self.first_letter=first_letter
  end

  def project_roles_of_project(projects_or_project)
    #Get intersection of all project memberships + person's memberships to find project membership
	  projects_or_project = Array(projects_or_project)
    memberships = group_memberships.select{|g| projects_or_project.include? g.work_group.project}
    return memberships.collect{|m| m.project_roles}.flatten
  end

  def assets
    created_data_files | created_models | created_sops | created_publications | created_presentations
  end

  #can be edited by:
  #(admin or project managers of this person) and (this person does not have a user or not the other admin)
  #themself
  def can_be_edited_by?(subject)
    return false unless subject
    subject = subject.user if subject.is_a?(Person)
    subject == self.user || subject.is_admin? || self.is_managed_by?(subject)
  end

  #determines if this person is the member of a project for which the user passed is a project manager,
  # #and the current person is not an admin
  def is_managed_by? user
    return false if self.is_admin?
    match = self.projects.find do |p|
      user.person.is_project_manager?(p)
    end
    !match.nil?
  end

  def me?
    user && user==User.current_user
  end

  #admin can administer other people, project manager can administer other people except other admins and themself
  def can_be_administered_by?(user)
    person = user.try(:person)
    return false unless user && person
    user.is_admin? || (person.is_project_manager_of_any_project? && (self.is_admin? || self!=person))
  end

  def can_view? user = User.current_user
    !user.nil? || !Seek::Config.is_virtualliver
  end

  def can_edit? user = User.current_user
    new_record? || can_be_edited_by?(user)
  end

  def can_manage? user = User.current_user
    user.try(:is_admin?)
  end

  def can_destroy? user = User.current_user
    can_manage? user
  end

  def title_is_public?
    true
  end

  def expertise= tags
    if tags.kind_of? Hash
      return tag_with_params(tags,"expertise")
    else
      return tag_with(tags,"expertise")
    end
  end

  def tools= tags
    if tags.kind_of? Hash
      tag_with_params tags,"tool"
    else
      tag_with tags,"tool"
    end
  end

  def expertise
    annotations_with_attribute("expertise").collect{|a| a.value}
  end

  def tools
    annotations_with_attribute("tool").collect{|a| a.value}
  end

    #retrieve the items that this person is contributor (owner for assay)
  def related_items
     related_items = []
     related_items |= assays
     unless user.blank?
       related_items |= user.assets
       related_items |= user.presentations
       related_items |= user.events
       related_items |= user.investigations
       related_items |= user.studies
     end
     related_items
  end

  #remove the permissions which are set on this person
  def remove_permissions
    permissions = Permission.where(["contributor_type =? and contributor_id=?", 'Person', id])
    permissions.each do |p|
      p.destroy
    end
  end

  def clean_up_and_assign_permissions
    #remove the permissions which are set on this person
    remove_permissions

    #retrieve the items that this person is contributor (owner for assay)
    person_related_items = related_items

    #check if anyone has manage right on the related_items
    #if not or if only the contributor then assign the manage right to pis||pals
    person_related_items.each do |item|
      people_can_manage_item = item.people_can_manage
      if people_can_manage_item.blank? || (people_can_manage_item == [[id, "#{name}", Policy::MANAGING]])
        #find the projects which this person and item belong to
        projects_in_common = projects & item.projects
        pis = projects_in_common.collect{|p| p.pis}.flatten.uniq
        pis.reject!{|pi| pi.id == id}
        item.policy_or_default
        policy = item.policy
        unless pis.blank?
          pis.each do |pi|
            policy.permissions.build(:contributor => pi, :access_type => Policy::MANAGING)
            policy.save
          end
        else
          pals = projects_in_common.collect{|p| p.pals}.flatten.uniq
          pals.reject!{|pal| pal.id == id}
          pals.each do |pal|
            policy.permissions.build(:contributor => pal, :access_type => Policy::MANAGING)
            policy.save
          end
        end
      end
    end
  end

  #a utitlity method to simply add a person to a project and institution
  #will automatically handle the WorkGroup and GroupMembership, and avoid creating duplicates
  def add_to_project_and_institution project, institution
    group = WorkGroup.where(:project_id=>project.id,:institution_id=>institution.id).first
    group ||= WorkGroup.new :project=>project, :institution=>institution

    membership = GroupMembership.where(:person_id=>id,:work_group_id=>group.id).first
    membership ||= GroupMembership.new :person=>self,:work_group=>group

    self.group_memberships << membership
  end

  private

  #a before_save trigger, that checks if the person is the first one created, and if so defines it as admin
  def first_person_admin
    self.is_admin = true if Person.count==0
  end

  def orcid_id_must_be_valid_or_blank
    unless orcid.blank? || valid_orcid_id?(orcid.gsub("http://orcid.org/",""))
        errors.add("Orcid identifier"," isn't a valid ORCID identifier.")
    end
  end

  #checks the structure of the id, and whether is conforms to ISO/IEC 7064:2003
  def valid_orcid_id? id
    if id =~ /[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9,X]{4}/
      id = id.gsub("-","")
      id[15] == orcid_checksum(id)
    else
      false
    end
  end

  #calculating the checksum according to ISO/IEC 7064:2003, MOD 11-2 ; see - http://support.orcid.org/knowledgebase/articles/116780-structure-of-the-orcid-identifier
  def orcid_checksum(id)
    total=0
    (0...15).each { |x| total = (total + id[x].to_i) * 2 }
    remainder = total % 11
    result = (12 - remainder) % 11
    result == 10 ? "X" : result.to_s
  end

  include Seek::ProjectHierarchies::PersonExtension if Seek::Config.project_hierarchy_enabled
end
