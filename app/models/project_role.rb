class ProjectRole < ActiveRecord::Base
  has_and_belongs_to_many :group_memberships

  alias_attribute :title,:name

  #returns the pal role - selected if the role contains ' Pal' (case insensitive; note the proceeding space
  def self.pal_role
    ProjectRole.all.find do |r|
      / pal/i =~ r.name
    end
  end

  def to_s
    title
  end

end
