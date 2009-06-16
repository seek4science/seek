class Role < ActiveRecord::Base
  has_and_belongs_to_many :group_memberships

  alias_attribute :title,:name
end
