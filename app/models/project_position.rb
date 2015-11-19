class ProjectPosition < ActiveRecord::Base
  has_many :group_memberships_project_positions
  has_many :group_memberships, :through => :group_memberships_project_positions

  alias_attribute :title,:name

  #returns the pal role - selected if the role contains ' Pal' (case insensitive; note the proceeding space
  def self.pal_position
    ProjectPosition.all.find do |p|
      / pal/i =~ p.name
    end
  end

  def self.project_coordinator_position
    ProjectPosition.all.find do |p|
      /project coordinator/i =~ p.name
    end
  end

  def to_s
    title
  end

end
