class ContributedResourceSerializer < BaseSerializer
  attributes :id, :title, :description, :latest_version, :version, :versions
  has_one :content_blob
end
