class GroupMembership < ActiveRecord::Base
  belongs_to :person
  belongs_to :work_group
  has_and_belongs_to_many :roles
end
