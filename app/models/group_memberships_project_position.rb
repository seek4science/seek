class GroupMembershipsProjectPosition < ActiveRecord::Base

  belongs_to :project_position
  belongs_to :group_membership

end
