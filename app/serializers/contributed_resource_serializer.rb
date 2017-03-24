class ContributedResourceSerializer < BaseSerializer
  attributes :id, :title, :description, :version, :versions
  has_one :content_blob

end
