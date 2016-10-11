require 'grouped_pagination'
require 'simple_crypt'
require 'title_trimmer'

class Project < ActiveRecord::Base
  include Seek::Rdf::RdfGeneration
  include Seek::Rdf::ReactToAssociatedChange

  acts_as_yellow_pages
  title_trimmer
  validates :title, uniqueness: true

  include SimpleCrypt

  has_and_belongs_to_many :investigations

  has_and_belongs_to_many :data_files
  has_and_belongs_to_many :models
  has_and_belongs_to_many :sops
  has_and_belongs_to_many :publications
  has_and_belongs_to_many :events
  has_and_belongs_to_many :presentations
  has_and_belongs_to_many :taverna_player_runs, class_name: 'TavernaPlayer::Run',
                                                join_table: 'projects_taverna_player_runs', association_foreign_key: 'run_id'

  has_and_belongs_to_many :strains
  has_and_belongs_to_many :organisms
  has_and_belongs_to_many :samples

  has_many :work_groups, dependent: :destroy
  has_many :institutions, through: :work_groups, before_remove: :group_memberships_empty?

  has_many :admin_defined_role_projects

  belongs_to :programme

  attr_accessible :project_administrator_ids, :asset_gatekeeper_ids, :pal_ids, :asset_housekeeper_ids, :title, :programme_id, :description,
                  :web_page, :institution_ids, :parent_id, :wiki_page, :organism_ids, :default_license

  # for handling the assignment for roles
  attr_accessor :project_administrator_ids, :asset_gatekeeper_ids, :pal_ids, :asset_housekeeper_ids
  after_save :handle_project_administrator_ids, if: '@project_administrator_ids'
  after_save :handle_asset_gatekeeper_ids, if: '@asset_gatekeeper_ids'
  after_save :handle_pal_ids, if: '@pal_ids'
  after_save :handle_asset_housekeeper_ids, if: '@asset_housekeeper_ids'

  # FIXME: temporary handler, projects need to support multiple programmes
  def programmes
    [programme].compact
  end

  # SEEK projects suffer from having 2 types of ancestor and descendant,that were added separately - those from the historical lineage of the project, and also from
  # the hierarchical tree structure that can be. For this reason and to avoid the clash, these anscestors and descendants have been renamed.
  # However, in the future it would probably be more appropriate to change these back to simply ancestor and descendant, and rename the hierarchy struture
  # to use parents/children.
  belongs_to :lineage_ancestor, class_name: 'Project', foreign_key: :ancestor_id
  has_many :lineage_descendants, class_name: 'Project', foreign_key: :ancestor_id

  scope :default_order, order('title')
  scope :without_programme, conditions: 'programme_id IS NULL'

  validates :web_page, url: {allow_nil: true, allow_blank: true}
  validates :wiki_page, url: {allow_nil: true, allow_blank: true}

  validate :lineage_ancestor_cannot_be_self

  # a default policy belonging to the project; this is set by a project PAL
  # if the project gets deleted, the default policy needs to be destroyed too
  # (no links to the default policy will be made from elsewhere; instead, when
  #  necessary, deep copies of it will be made to ensure that all settings get
  #  fully copied and assigned to belong to owners of assets, where identical policy
  #  is to be used)
  belongs_to :default_policy,
             class_name: 'Policy',
             dependent: :destroy,
             autosave: true

  after_initialize :default_default_policy_if_new

  def default_default_policy_if_new
    unless Seek::Config.is_virtualliver
      self.default_policy = Policy.default if new_record?
    else
      self.default_policy = Policy.private_policy if new_record?
    end
  end

  def group_memberships_empty?(institution)
    work_group = WorkGroup.where(['project_id=? AND institution_id=?', id, institution.id]).first
    unless work_group.people.empty?
      fail WorkGroupDeleteError.new('You can not delete the ' + work_group.description + '. This Work Group has ' + work_group.people.size.to_s + " people associated with it.
                           Please disassociate first the people from this Work Group.")
    end
  end

  alias_attribute :webpage, :web_page
  alias_attribute :internal_webpage, :wiki_page

  has_and_belongs_to_many :organisms, before_add: :update_rdf_on_associated_change, before_remove: :update_rdf_on_associated_change
  has_many :project_subscriptions, dependent: :destroy

  attr_accessor :site_username, :site_password

  before_save :set_credentials

  def assets
    data_files | sops | models | publications | presentations
  end

  def institutions=(new_institutions)
    new_institutions.each_index do |i|
      new_institutions[i] = Institution.find(new_institutions[i]) unless new_institutions.is_a?(Institution)
    end
    work_groups.each do |wg|
      wg.destroy unless new_institutions.include?(wg.institution)
    end
    for institution in new_institutions
      institutions << institution unless institutions.include?(institution)
    end
  end

  # this is project role
  def pis
    pi_role = ProjectPosition.find_by_name('PI')
    people.select { |p| p.project_positions_of_project(self).include?(pi_role) }
  end

  # this is seek role
  def asset_housekeepers
    people_with_the_role(Seek::Roles::ASSET_HOUSEKEEPER)
  end

  # this is seek role
  def project_administrators
    people_with_the_role(Seek::Roles::PROJECT_ADMINISTRATOR)
  end

  # this is seek role
  def asset_gatekeepers
    people_with_the_role(Seek::Roles::ASSET_GATEKEEPER)
  end

  def pals
    people_with_the_role(Seek::Roles::PAL)
  end

  # returns people belong to the admin defined seek 'role' for this project
  def people_with_the_role(role)
    Seek::Roles::ProjectRelatedRoles.instance.people_with_project_and_role(self, role)
  end

  def locations
    # infer all project's locations from the institutions where the person is member of
    locations = institutions.collect(&:country).select { |l| !l.blank? }
    locations
  end

  # OVERRIDDEN in Seek::ProjectHierarchy if Seek::Config.project_hierarchy_enabled
  def people
    # TODO: look into doing this with a scope or direct query
    res = work_groups.collect(&:people).flatten.uniq.compact
    # TODO: write a test to check they are ordered
    res.sort_by { |a| (a.last_name.blank? ? a.name : a.last_name) }
  end

  def studies
    investigations.collect(&:studies).flatten.uniq
  end

  def assays
    studies.collect(&:assays).flatten.uniq
  end

  def set_credentials
    unless site_username.nil? && site_password.nil?
      cred = { username: site_username, password: site_password }
      cred = encrypt(cred, generate_key(GLOBAL_PASSPHRASE))
      self.site_credentials = Base64.encode64(cred).encode('utf-8')
    end
  end

  def decrypt_credentials
    decoded = Base64.decode64 site_credentials
    cred = decrypt(decoded, generate_key(GLOBAL_PASSPHRASE))
    self.site_password = cred[:password]
    self.site_username = cred[:username]
  rescue
  end

  # indicates whether this project has a person, or associated user, as a member
  def has_member?(user_or_person)
    user_or_person = user_or_person.try(:person)
    people.include? user_or_person
  end

  def person_roles(person)
    # Get intersection of all project memberships + person's memberships to find project membership
    project_memberships = work_groups.collect(&:group_memberships).flatten
    person_project_membership = person.group_memberships & project_memberships
    person_project_membership.project_positions
  end

  def can_be_edited_by?(user)
    user && (has_member?(user) || can_be_administered_by?(user))
  end

  # whether this project can be administered by the given user, or current user if none is specified
  def can_be_administered_by?(user = User.current_user)
    return false unless user
    user.is_admin? || user.is_project_administrator?(self) || user.is_programme_administrator?(programme)
  end

  # all projects that can be administered by the given user, or ghe current user if none is specified
  def self.all_can_be_administered(user = User.current_user)
    Project.all.select do |project|
      project.can_be_administered_by?(user)
    end
  end

  def can_edit?(user = User.current_user)
    new_record? || can_be_edited_by?(user)
  end

  def can_delete?(user = User.current_user)
    user && user.is_admin? && work_groups.collect(&:people).flatten.empty?
  end

  def lineage_ancestor_cannot_be_self
    if lineage_ancestor == self
      errors.add(:lineage_ancestor, 'cannot be the same as itself')
    end
  end

  # allows a new project to be spawned off as a descendant of this project, retaining the same membership but existing
  # as a new project entity. attributes may be passed to override those being copied. The ancestor and memberships will
  # automatically be assigned and carried over, and the avatar will be set to nil
  def spawn(attributes = {})
    child = dup
    work_groups.each do |wg|
      new_wg = WorkGroup.new(institution: wg.institution, project: child)
      child.work_groups << new_wg
      wg.group_memberships.each do |gm|
        new_gm = GroupMembership.new(person: gm.person, work_group: wg)
        new_wg.group_memberships << new_gm
      end
    end
    child.assign_attributes(attributes)
    child.avatar = nil
    child.lineage_ancestor = self
    child
  end

  def self.can_create?
    User.admin_logged_in? || User.activated_programme_administrator_logged_in?
  end

  # set the administrators, assigned from the params to :project_administrator_ids
  def handle_project_administrator_ids
    handle_admin_role_ids Seek::Roles::PROJECT_ADMINISTRATOR
  end

  # set the gatekeepers, assigned from the params to :asset_gatekeeper_ids
  def handle_asset_gatekeeper_ids
    handle_admin_role_ids Seek::Roles::ASSET_GATEKEEPER
  end

  # set the pals, assigned from the params to :pal_ids
  def handle_pal_ids
    handle_admin_role_ids Seek::Roles::PAL
  end

  # set the asset housekeepers, assigned from the params to :asset_housekeeper_ids
  def handle_asset_housekeeper_ids
    handle_admin_role_ids Seek::Roles::ASSET_HOUSEKEEPER
  end

  # general method for assigning the people with roles, according to the role passed in.
  # e.g. for a role of :gatekeeper, gatekeeper_ids attribute is used to set the people for that role
  def handle_admin_role_ids(role)
    current_members = send(role.to_s.pluralize)
    new_members = Person.find(send("#{role}_ids"))

    to_add = new_members - current_members
    to_remove = current_members - new_members
    to_add.each do |person|
      person.send("is_#{role}=", [true, self])
      disable_authorization_checks { person.save! }
    end
    to_remove.each do |person|
      person.send("is_#{role}=", [false, self])
      disable_authorization_checks { person.save! }
    end
  end

  def total_asset_size
    assets.sum do |asset|
      if asset.respond_to?(:content_blob)
        asset.content_blob.file_size || 0
      elsif asset.respond_to?(:content_blobs)
        asset.content_blobs.sum do |blob|
          blob.file_size || 0
        end
      else
        0
      end
    end
  end

  # should put below at the bottom in order to override methods for hierarchies,
  # Try to find a better way for overriding methods regardless where to include the module
  include Seek::ProjectHierarchies::ProjectExtension if Seek::Config.project_hierarchy_enabled
end
