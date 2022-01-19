class Project < ApplicationRecord
  include Seek::Annotatable
  include HasSettings

  acts_as_yellow_pages
  title_trimmer

  has_and_belongs_to_many :investigations
  has_many :studies, through: :investigations
  has_many :assays, through: :studies
  has_and_belongs_to_many :data_files
  has_and_belongs_to_many :models
  has_and_belongs_to_many :sops
  has_and_belongs_to_many :workflows
  has_and_belongs_to_many :nodes
  has_and_belongs_to_many :publications
  has_and_belongs_to_many :events
  has_and_belongs_to_many :presentations
  has_and_belongs_to_many :strains
  has_and_belongs_to_many :samples
  has_and_belongs_to_many :sample_types
  has_and_belongs_to_many :documents
  has_and_belongs_to_many :collections
  has_and_belongs_to_many :templates

  has_many :work_groups, dependent: :destroy, inverse_of: :project
  has_many :institutions, through: :work_groups, inverse_of: :projects
  has_many :group_memberships, through: :work_groups, inverse_of: :project
  # OVERRIDDEN in Seek::ProjectHierarchy if Seek::Config.project_hierarchy_enabled
  has_many :people, -> { distinct }, through: :group_memberships

  has_many :former_group_memberships, -> { where('time_left_at IS NOT NULL AND time_left_at <= ?', Time.now) },
           through: :work_groups, source: :group_memberships
  has_many :former_people, through: :former_group_memberships, source: :person

  has_many :current_group_memberships, -> { where('time_left_at IS NULL OR time_left_at > ?', Time.now) },
           through: :work_groups, source: :group_memberships
  has_many :current_people, through: :current_group_memberships, source: :person

  has_many :admin_defined_role_projects

  has_many :openbis_endpoints

  has_annotation_type :funding_code

  belongs_to :programme
  has_filter programme: Seek::Filtering::Filter.new(
      value_field: 'programmes.id',
      label_field: 'programmes.title',
      joins: [:programme]
  )

  # for handling the assignment for roles
  attr_accessor :project_administrator_ids, :asset_gatekeeper_ids, :pal_ids, :asset_housekeeper_ids
  after_save :handle_project_administrator_ids, if: -> { @project_administrator_ids }
  after_save :handle_asset_gatekeeper_ids, if: -> { @asset_gatekeeper_ids }
  after_save :handle_pal_ids, if: -> { @pal_ids }
  after_save :handle_asset_housekeeper_ids, if: -> { @asset_housekeeper_ids }

  scope :without_programme, -> { where('programme_id IS NULL') }

  auto_strip_attributes :web_page, :wiki_page

  validates :web_page, url: {allow_nil: true, allow_blank: true}
  validates :wiki_page, url: {allow_nil: true, allow_blank: true}

  validates :title, uniqueness: true
  validates :title, length: { maximum: 255 }
  validates :description, length: { maximum: 65_535 }

  validate :validate_end_date

  # a default policy belonging to the project; this is set by a project PAL
  # if the project gets deleted, the default policy needs to be destroyed too
  # (no links to the default policy will be made from elsewhere; instead, when
  #  necessary, deep copies of it will be made to ensure that all settings get
  #  fully copied and assigned to belong to owners of assets, where identical policy
  #  is to be used)
  belongs_to :default_policy, class_name: 'Policy', dependent: :destroy, autosave: true

  # FIXME: temporary handler, projects need to support multiple programmes
  def programmes
    Programme.where(id: programme_id)
  end

  alias_attribute :webpage, :web_page
  alias_attribute :internal_webpage, :wiki_page

  has_and_belongs_to_many :organisms, before_add: :update_rdf_on_associated_change, before_remove: :update_rdf_on_associated_change
  has_and_belongs_to_many :human_diseases, before_add: :update_rdf_on_associated_change, before_remove: :update_rdf_on_associated_change
  has_filter :organism
  has_filter :human_disease
  has_many :project_subscriptions, dependent: :destroy

  has_many :dependent_permissions, class_name: 'Permission', as: :contributor, dependent: :destroy

  def assets
    data_files | sops | models | publications | presentations | documents | workflows | nodes | collections
  end

  def institutions=(new_institutions)
    new_institutions = Array(new_institutions).map do |i|
      i.is_a?(Institution) ? i : Institution.find(i)
    end
    work_groups.each do |wg|
      wg.destroy unless new_institutions.include?(wg.institution)
    end
    new_institutions.each do |i|
      institutions << i unless institutions.include?(i)
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
    
  # Returns the columns to be shown on the table view for the resource
  def columns_default
    super + ['web_page']
  end
  def columns_allowed
    columns_default + ['wiki_page','start_date','end_date']
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

  def site_password
    settings.get('site_password')
  end

  def site_password= password
    settings.set('site_password', password)
  end

  def site_username
    settings.get('site_username')
  end

  def site_username= username
    settings.set('site_username', username)
  end

  def nels_enabled
    settings.get('nels_enabled')
  end

  def nels_enabled= checkbox_value
    settings.set('nels_enabled', !(checkbox_value == '0' || !checkbox_value))
  end

  # indicates whether this project has a person, or associated user, as a member
  def has_member?(user_or_person)
    user_or_person = user_or_person.try(:person)
    current_people.include? user_or_person
  end

  def human_disease_terms
    human_diseases.collect(&:searchable_terms).flatten
  end

  def members= replacement_members
    current = self.current_group_memberships.collect {|g| {:person_id => g.person_id, :institution_id => g.institution.id}}
    replacement = replacement_members.collect {|rm| {:person_id => rm['person_id'].to_i, :institution_id => rm['institution_id'].to_i}}

    to_remove = current - replacement
    to_add = replacement - current

    unless to_add.nil?
      to_add.each do |new_info|
        person = Person.find(new_info[:person_id])
        institution = Institution.find(new_info[:institution_id])
        unless person.nil? || institution.nil?
          person.add_to_project_and_institution(self, institution)
          person.save!
        end
      end
    end

    unless to_remove.nil?
      to_remove.each do |r|
        person = Person.find(r[:person_id])
        institution = Institution.find(r[:institution_id])
        gms = self.current_group_memberships.all.select {|gm| gm.person.id == r[:person_id] && gm.institution.id == r[:institution_id]}
        unless gms.empty?
          person.group_memberships.destroy(gms.first)
        end
      end

    end
  end

  def person_roles(person)
    # Get intersection of all project memberships + person's memberships to find project membership
    project_memberships = work_groups.collect(&:group_memberships).flatten
    person_project_membership = person.group_memberships & project_memberships
    person_project_membership.project_positions
  end

  def can_edit?(user = User.current_user)
    return false unless user
    return true if new_record? && self.class.can_create?
    has_member?(user) || can_manage?(user)
  end

  def can_manage?(user = User.current_user)
    return false unless user
    user.is_admin? || user.is_project_administrator?(self) || user.is_programme_administrator?(programme)
  end

  def can_delete?(user = User.current_user)
    user && can_manage?(user) &&
        investigations.empty? && studies.empty? && assays.empty? && assets.empty? &&
        samples.empty? && sample_types.empty?
  end

  def self.can_create?(user = User.current_user)
    User.admin_logged_in? ||
      User.activated_programme_administrator_logged_in? ||
        (user && Programme.any? { |p| p.allows_user_projects? })
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
        asset.content_blob.try(:file_size) || 0
      elsif asset.respond_to?(:content_blobs)
        asset.content_blobs.to_a.sum do |blob|
          blob.file_size || 0
        end
      else
        0
      end
    end
  end

  # whether the user is able to request membership of this project
  def allow_request_membership?(user = User.current_user)
    user.present? &&
      project_administrators.any? &&
      !has_member?(user) &&
      ProjectMembershipMessageLog.recent_requests(user.try(:person),self).empty?
  end

  def validate_end_date
    errors.add(:end_date, 'is before start date.') unless end_date.nil? || start_date.nil? || end_date >= start_date
  end

  def positioned_investigations
    investigations.order(position: :asc)
  end

  def ro_crate_metadata
    {
        '@id' => "#project-#{id}",
        name: title,
        identifier: rdf_seek_id
    }.tap do |m|
      m.merge!(url: web_page) unless web_page.blank?
    end
  end

  # should put below at the bottom in order to override methods for hierarchies,
  # Try to find a better way for overriding methods regardless where to include the module
  if Seek::Config.project_hierarchy_enabled
    include Seek::ProjectHierarchies::ProjectExtension
  end
end
