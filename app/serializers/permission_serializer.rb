class PermissionSerializer < SimpleBaseSerializer
  attribute :access_type
  has_one :contributor
end