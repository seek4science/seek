class ContributedResourceSerializer < PCSSerializer
  attributes :id, :title, :description, :latest_version, :version, :versions
  has_one :content_blob

  has_many :tags do
    object.annotations
  end

end
