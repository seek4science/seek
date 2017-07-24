class ContributedResourceSerializer < PCSSerializer
  attributes :title, :description, :latest_version, :version, :versions
  has_one :content_blob, include_data:true

  has_many :tags, include_data:true do
    object.annotations
  end

end
