class ContributedResourceSerializer < BaseSerializer
  attributes :id, :title, :description, :latest_version, :version, :versions
  has_many :creators
  has_one :submitter do
    determine_submitter object
  end
  has_one :policy
  has_one :content_blob

  has_many :tags do
    object.annotations
  end

end
