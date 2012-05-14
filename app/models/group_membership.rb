class GroupMembership < ActiveRecord::Base
  belongs_to :person, :touch => true
  belongs_to :work_group
  has_and_belongs_to_many :project_roles

end
