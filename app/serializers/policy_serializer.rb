class PolicySerializer < SimpleBaseSerializer
  attributes :title, :sharing_scope, :access_type,
             :use_blacklist, :use_whitelist
  has_many :permissions, include_data:true

end