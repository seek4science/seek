require 'grouped_pagination'

class Person < ActiveRecord::Base

  acts_as_yellow_pages
  default_scope :order => "last_name, first_name"

  before_save :first_person_admin
  before_destroy :clean_up_and_assign_permissions

  acts_as_notifiee
  acts_as_annotatable :name_field=>:name
  include Seek::Taggable

  def receive_notifications
    registered? and super
  end
  
  def registered?
    !user.nil?
  end

  #grouped_pagination :pages=>("A".."Z").to_a #shouldn't need "Other" tab for people
  #load the configuration for the pagination
  grouped_pagination :pages=>("A".."Z").to_a, :default_page => Seek::Config.default_page(self.name.underscore.pluralize)

  validates_presence_of :email

  #FIXME: consolidate these regular expressions into 1 holding class
  validates_format_of :email,:with=>RFC822::EmailAddress
  validates_format_of :web_page, :with=>/(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix,:allow_nil=>true,:allow_blank=>true

  validates_uniqueness_of :email,:case_sensitive => false

  has_and_belongs_to_many :disciplines

  has_many :group_memberships, :dependent => :destroy

  has_many :favourite_group_memberships, :dependent => :destroy
  has_many :favourite_groups, :through => :favourite_group_memberships

  has_many :work_groups, :through=>:group_memberships, :before_add => proc {|person, wg| person.project_subscriptions.build :project => wg.project unless person.project_subscriptions.detect {|ps| ps.project == wg.project}}
  has_many :studies, :foreign_key => :person_responsible_id
  has_many :assays,:foreign_key => :owner_id

  has_one :user, :dependent=>:destroy

  has_many :assets_creators, :dependent => :destroy, :foreign_key => "creator_id"
  has_many :created_data_files, :through => :assets_creators, :source => :asset, :source_type => "DataFile"
  has_many :created_models, :through => :assets_creators, :source => :asset, :source_type => "Model"
  has_many :created_sops, :through => :assets_creators, :source => :asset, :source_type => "Sop"
  has_many :created_publications, :through => :assets_creators, :source => :asset, :source_type => "Publication"
  has_many :created_presentations,:through => :assets_creators,:source=>:asset,:source_type => "Presentation"

  searchable do
    text :first_name, :last_name,:searchable_tags,:locations, :project_roles
    text :disciplines do
      disciplines.map{|d| d.title}
    end
  end if Seek::Config.solr_enabled

  named_scope :without_group, :include=>:group_memberships, :conditions=>"group_memberships.person_id IS NULL"
  named_scope :registered,:include=>:user,:conditions=>"users.person_id != 0"
  named_scope :pals,:conditions=>{:is_pal=>true}
  named_scope :admins,:conditions=>{:is_admin=>true}

  alias_attribute :webpage,:web_page

  has_many :project_subscriptions, :before_add => proc {|person, ps| ps.person = person},:dependent => :destroy
  accepts_nested_attributes_for :project_subscriptions, :allow_destroy => true

  has_many :subscriptions,:dependent => :destroy
  before_create :set_default_subscriptions

  ROLES = %w[admin pal pi]

  def is_admin?
     roles.include?('admin')
  end

  def set_default_subscriptions
    projects.each do |proj|
      project_subscriptions.build :project => proj
    end
  end

  #FIXME: change userless_people to use this scope - unit tests
  named_scope :not_registered,:include=>:user,:conditions=>"users.person_id IS NULL"

  def self.userless_people
    p=Person.find(:all)
    return p.select{|person| person.user.nil?}
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
    all_people = Person.find(:all, :order => "ID asc")
    names_emails = all_people.collect{ |p| {"id" => p.id,
        "name" => (p.first_name.blank? ? (logger.error("\n----\nUNEXPECTED DATA: person id = #{p.id} doesn't have a first name\n----\n"); "(NO FIRST NAME)") : p.first_name) + " " +
                  (p.last_name.blank? ? (logger.error("\n----\nUNEXPECTED DATA: person id = #{p.id} doesn't have a last name\n----\n"); "(NO LAST NAME)") : p.last_name),
        "email" => (p.email.blank? ? "unknown" : p.email) } }
    return names_emails.to_json
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

  def people_i_may_know
    res=[]
    institutions.each do |i|
      i.people.each do |p|
        res << p unless p==self or res.include? p
      end
    end

    projects.each do |proj|
      proj.people.each do |p|
        res << p unless p==self or res.include? p
      end
    end
    return  res
  end

  def institutions
    work_groups.scoped(:include => :institution).collect {|wg| wg.institution }.uniq
  end

  def projects
    #updating workgroups doesn't change groupmemberships until you save. And vice versa.
    @known_projects ||= work_groups.collect {|wg| wg.project }.uniq | group_memberships.collect{|gm| gm.work_group.project}
    @known_projects
  end

  def member?
    !projects.empty?
  end

  def member_of?(item_or_array)
    array = [item_or_array].flatten
    array.detect {|item| projects.include?(item)}
  end

  def locations
    # infer all person's locations from the institutions where the person is member of
    locations = self.institutions.collect { |i| i.country unless i.country.blank? }

    # make sure this list is unique and (if any institutions didn't have a country set) that 'nil' element is deleted
    locations = locations.uniq
    locations.delete(nil)

    return locations
  end

  def email_with_name
    name + " <" + email + ">"
  end

  def name
    firstname=first_name
    firstname||=""
    lastname=last_name
    lastname||=""
    #capitalize, including double barrelled names
    #TODO: why not just store them like this rather than processing each time? Will need to reprocess exiting entries if we do this.
    return (firstname.gsub(/\b\w/) {|s| s.upcase} + " " + lastname.gsub(/\b\w/) {|s| s.upcase}).strip
  end

  #the roles defined within SEEK
  def roles=(roles)
    if can_manage?
      self.roles_mask = (roles & ROLES).map { |r| 2**ROLES.index(r) }.sum
      self.save
    end
  end

  def roles
    ROLES.reject do |r|
      ((roles_mask || 0) & 2**ROLES.index(r)).zero?
    end
  end

  def add_roles=(roles)
    if can_manage?
      add_roles = roles - (roles & self.roles)
      self.roles_mask += (add_roles & ROLES).map { |r| 2**ROLES.index(r) }.sum
      self.save
    end
  end

  def remove_roles roles
    if can_manage?
      remove_roles = roles & self.roles
      self.roles_mask -= (remove_roles & ROLES).map { |r| 2**ROLES.index(r) }.sum
      self.save
    end
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

  def project_roles_of_project(project)
    #Get intersection of all project memberships + person's memberships to find project membership
    memberships = group_memberships.select{|g| g.work_group.project == project}
    return memberships.collect{|m| m.project_roles}.flatten
  end

  def assets
    created_data_files | created_models | created_sops | created_publications | created_presentations
  end

  def can_be_edited_by?(subject)
    subject == nil ? false : ((subject.is_admin? || subject.is_project_manager?) && (self.user.nil? || !self.is_admin?))
  end

 
  def can_view? user = User.current_user
    !user.nil? || !Seek::Config.is_virtualliver
  end

  def can_edit? user = User.current_user
    new_record? or user && (user.is_admin? || user.is_project_manager? || user == self.user)
  end

  does_not_require_can_edit :is_admin
  requires_can_manage :is_admin, :can_edit_projects, :can_edit_institutions

  def can_manage? user = User.current_user
    try_block{user.is_admin?}
  end

  def can_destroy? user = User.current_user
    can_manage? user
  end

  def title_is_public?
    true
  end

  def expertise= tags
    if tags.kind_of? Hash
      tag_with_params tags,"expertise"
    else
      tag_with tags,"expertise"
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
    permissions = Permission.find(:all, :conditions => ["contributor_type =? and contributor_id=?", 'Person', id])
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
      if people_can_manage_item.blank? || (people_can_manage_item == [[id, "#{first_name} #{last_name}", Policy::MANAGING]])
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

  private

  #a before_save trigger, that checks if the person is the first one created, and if so defines it as admin
  def first_person_admin
    self.is_admin=true if Person.count==0
  end


end
