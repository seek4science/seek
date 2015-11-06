class GroupMembershipsProjectRole < ActiveRecord::Base

  belongs_to :project_role
  belongs_to :group_membership

end
