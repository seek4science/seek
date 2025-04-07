class Institution < ApplicationRecord

  acts_as_yellow_pages
  title_trimmer

  auto_strip_attributes :web_page

  before_validation :fetch_ror_details, if: -> { ror_id.present? && ror_id_changed? }

  validates :title, uniqueness: true
  validates :ror_id, uniqueness: true, allow_blank: true
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
    user&.person&.is_project_administrator_of_any_project? || user&.person&.is_programme_administrator_of_any_programme?
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

  private

  def fetch_ror_details

    ror_client = Ror::Client.new
    response = ror_client.fetch_by_id(ror_id)

    if response[:error]
      errors.add(:ror_id, response[:error])
      return
    end

    self.title = response['name']
    self.city = response.dig('addresses', 0, 'city')
    self.country = response.dig('country', 'country_code')
    self.web_page = response.dig('links', 0)

  end



end
