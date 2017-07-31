class ContributedResourceSerializer < PCSSerializer
  attributes :title, :description, :latest_version, :version, :versions
  has_one :content_blob, include_data:true

end
