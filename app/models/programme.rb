class Programme < ActiveRecord::Base
  attr_accessible :avatar_id, :description, :first_letter, :title, :uuid, :web_page, :project_ids, :funding_details

  searchable(:auto_index=>false) do
    text :funding_details
    text :institutions do
      institutions.compact.map(&:title)
    end
  end if Seek::Config.solr_enabled
  acts_as_yellow_pages

  #associations
  has_many :projects, :dependent=>:nullify
  accepts_nested_attributes_for :projects

  #validations
  validates :title,:uniqueness=>true

  scope :default_order, order('title')

  def people
    projects.collect{|p| p.people}.flatten.uniq
  end

  def institutions
    projects.collect{|p| p.institutions}.flatten.uniq
  end

  def can_be_edited_by?(user)
    can_edit?(user)
  end

  def can_edit?(user=User.current_user)
    user && (new_record? || user.is_admin? || user.person.is_programme_administrator?(self))
  end

  def can_delete?(user=User.current_user)
    User.admin_logged_in?
  end

  def self.can_create?
    User.logged_in_and_registered? && Seek::Config.programmes_enabled
  end

  def administrators
    Seek::Roles::ProgrammeRelatedRoles.instance.people_with_programme_and_role(self,"programme_administrator")
  end

end

