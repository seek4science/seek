class Programme < ApplicationRecord
  include Seek::Annotatable
  include Seek::Roles::Scope

  if Seek::Config.solr_enabled
    searchable(auto_index: false) do
      text :funding_details
      text :institutions do
        institutions.compact.map(&:title)
      end
    end
  end

  acts_as_yellow_pages

  # associations
  has_many :projects, dependent: :nullify
  has_many :work_groups, through: :projects
  has_many :group_memberships, through: :work_groups
  has_many :people, -> { distinct }, through: :group_memberships
  has_many :institutions, -> { distinct }, through: :work_groups
  has_many :dependent_permissions, class_name: 'Permission', as: :contributor, dependent: :destroy
  has_many :organisms, -> { distinct }, through: :projects
  has_many :investigations, -> { distinct }, through: :projects
  has_many :studies, -> { distinct }, through: :investigations
  has_many :assays, -> { distinct }, through: :studies
  %i[data_files documents models sops presentations events publications samples workflows].each do |type|
    has_many type, -> { distinct }, through: :projects
  end
  has_many :programme_administrator_roles, -> { where(role_type_id: RoleType.find_by_key!(:programme_administrator)) }, as: :scope, class_name: 'Role', inverse_of: :scope
  has_many :programme_administrators, through: :programme_administrator_roles, class_name: 'Person', source: :person
  accepts_nested_attributes_for :projects

  auto_strip_attributes :web_page

  # validations
  validates :title, uniqueness: true
  validates :title, length: { maximum: 255 }
  validates :description, length: { maximum: 65_535 }

  validates :web_page, url: { allow_nil: true, allow_blank: true }

  before_create :activate_on_create

  # scopes
  scope :activated, -> { where(is_activated: true) }
  scope :not_activated, -> { where(is_activated: false) }
  scope :rejected, -> { where('is_activated = ? AND activation_rejection_reason IS NOT NULL', false) }
  scope :open_for_projects, -> { where(open_for_projects: true) }

  has_annotation_type :funding_code
  has_many :funding_codes_as_text, through: :funding_code_annotations, source: :value, source_type: 'TextValue'
  has_filter funding_code: Seek::Filtering::Filter.new(
      value_field: 'text_values.id',
      label_field: 'text_values.text',
      joins: [:funding_codes_as_text]
  )

  def related_people
    people | programme_administrators
  end

  def self.site_managed_programme
    Programme.find_by_id(Seek::Config.managed_programme_id)
  end

  def site_managed?
    self == Programme.site_managed_programme
  end

  def human_diseases
    projects.collect(&:human_diseases).flatten.uniq
  end

  def assets
    (data_files + models + sops + presentations + events + publications + documents).uniq.compact
  end

  def has_member?(user_or_person)
    projects.detect { |proj| proj.has_member?(user_or_person.try(:person)) }
  end

  def can_edit?(user = User.current_user)
    new_record? || can_manage?(user)
  end

  def can_manage?(user = User.current_user)
    user && (user.is_admin? || user.person.is_programme_administrator?(self))
  end

  def can_delete?(user = User.current_user)
    user && projects.empty? && (user.is_admin? || user.person.is_programme_administrator?(self))
  end

  def rejected?
    !(activation_rejection_reason.nil? || is_activated?)
  end

  # callback, activates if current user is an admin or nil, otherwise it needs activating
  def activate
    if can_activate?
      update_attribute(:is_activated, true)
      update_attribute(:activation_rejection_reason, nil)
    end
  end

  def can_activate?(user = User.current_user)
    user && user.is_admin? && !is_activated?
  end

  # whether there is permission to associate projects
  def can_associate_projects?(user = User.current_user)
    can_manage?(user) || allows_user_projects?
  end

  def allows_user_projects?
    Seek::Config.programmes_open_for_projects_enabled && open_for_projects?
  end

  def self.any_programmes_open_for_projects?
    return false unless Seek::Config.programmes_open_for_projects_enabled

    open_for_projects.any?
  end

  def self.can_create?
    return false unless Seek::Config.programmes_enabled

    User.admin_logged_in? || (User.logged_in_and_registered? && Seek::Config.programme_user_creation_enabled)
  end

  def total_asset_size
    projects.to_a.sum(&:total_asset_size)
  end

  private

  # callback, activates if current user is an admin or nil, otherwise it needs activating
  def activate_on_create
    self.is_activated = if User.current_user && !User.current_user.is_admin?
                          false
                        else
                          true
                        end
    true
  end
end
