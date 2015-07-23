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
    !user.nil? && user.is_admin?
  end

  def administrators
    Seek::Roles::ProgrammeDependentRoles.instance.people_with_programme_and_role(self,"programme_administrator")
  end

end

