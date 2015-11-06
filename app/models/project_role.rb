class ProjectRole < ActiveRecord::Base
  has_many :group_memberships_project_roles
  has_many :group_memberships, :through => :group_memberships_project_roles

  alias_attribute :title,:name

  #returns the pal role - selected if the role contains ' Pal' (case insensitive; note the proceeding space
  def self.pal_role
    ProjectRole.all.find do |r|
      / pal/i =~ r.name
    end
  end

  def self.project_coordinator_role
    ProjectRole.all.find do |r|
      /project coordinator/i =~ r.name
    end
  end

  def to_s
    title
  end

end
