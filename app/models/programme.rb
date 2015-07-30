class Programme < ActiveRecord::Base
  attr_accessible :avatar_id, :description, :first_letter, :title, :uuid, :web_page, :project_ids, :funding_details, :administrator_ids

  attr_accessor :administrator_ids

  searchable(auto_index: false) do
    text :funding_details
    text :institutions do
      institutions.compact.map(&:title)
    end
  end if Seek::Config.solr_enabled
  acts_as_yellow_pages

  # associations
  has_many :projects, dependent: :nullify
  accepts_nested_attributes_for :projects

  # validations
  validates :title, uniqueness: true
  after_save :handle_administrator_ids, if: '@administrator_ids'

  scope :default_order, order('title')

  def people
    projects.collect(&:people).flatten.uniq
  end

  def institutions
    projects.collect(&:institutions).flatten.uniq
  end

  def can_be_edited_by?(user)
    can_edit?(user)
  end

  def can_edit?(user = User.current_user)
    new_record? || can_manage?(user)
  end

  def can_manage?(user = User.current_user)
    user && (user.is_admin? || user.person.is_programme_administrator?(self))
  end

  def can_delete?(_user = User.current_user)
    User.admin_logged_in?
  end

  def self.can_create?
    User.logged_in_and_registered? && Seek::Config.programmes_enabled
  end

  def administrators
    Seek::Roles::ProgrammeRelatedRoles.instance.people_with_programme_and_role(self, 'programme_administrator')
  end

  # set the administrators, assigned from the params to :adminstrator_ids
  def handle_administrator_ids
    new_administrators = Person.find(administrator_ids)
    to_add = new_administrators - administrators
    to_remove = administrators - new_administrators
    to_add.each do |person|
      person.is_programme_administrator = true, self
      disable_authorization_checks { person.save! }
    end
    to_remove.each do |person|
      person.is_programme_administrator = false, self
      disable_authorization_checks { person.save! }
    end
  end
end
