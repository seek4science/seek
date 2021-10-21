class Institution < ApplicationRecord

  acts_as_yellow_pages
  title_trimmer

  auto_strip_attributes :web_page

  validates :title, uniqueness: true
  validates :web_page, url: { allow_nil: true, allow_blank: true }
  validates :country, country: true

  has_many :work_groups, dependent: :destroy, inverse_of: :institution
  has_many :projects, through: :work_groups,  inverse_of: :institutions
  has_many :programmes, -> { distinct }, through: :projects, inverse_of: :institutions
  has_filter :programme, :project, :country
  has_many :group_memberships, through: :work_groups, inverse_of: :institutions
  has_many :people, -> { order('last_name ASC').distinct }, through: :group_memberships, inverse_of: :institutions
  has_many :dependent_permissions, class_name: 'Permission', as: :contributor, dependent: :destroy

  searchable(auto_index: false) do
    text :city, :address
  end if Seek::Config.solr_enabled

  def can_edit?(user = User.current_user)
    return false unless user
    return true if new_record? && self.class.can_create?
    user.is_admin? || self.is_managed_by?(user)
  end

  # determines if this person is the member of a project for which the user passed is a project manager
  def is_managed_by?(user)
    projects.any? do |p|
      user.person.is_project_administrator?(p)
    end
  end

  # Returns the columns to be shown on the table view for the resource
  def columns_default
    super + ['city','country','web_page']
  end
  def columns_allowed
    columns_default + ['address']
  end

  # get a listing of all known institutions
  def self.get_all_institutions_listing
    Institution.all.collect { |i| [i.title, i.id] }
  end

  def can_delete?(user = User.current_user)
    (user&.is_admin? && work_groups.collect(&:people).flatten.empty?)
  end

  def self.can_create?
    User.admin_or_project_administrator_logged_in? ||
      User.activated_programme_administrator_logged_in?
  end

  def typeahead_hint
    unless city.blank?
      "#{city}, #{CountryCodes.country(country)}"
    else
      CountryCodes.country(country)
    end
  end
end
