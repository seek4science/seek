class GroupMembershipsProjectPosition < ApplicationRecord

  belongs_to :project_position
  belongs_to :group_membership

end
