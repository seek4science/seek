class PresentationSerializer < BaseSerializer
  has_many :people
  has_many :projects
  has_many :investigations
  has_many :studies
  has_many :assays
  has_many :publications
  has_many :events

  attributes :title, :description, :license

  attribute :version, key: :latest_version

  attribute :requested_version do
    v = @scope[:requested_version]
    if v.nil?
      v = object.version
    end

    requested_version = object.find_version(v)

    requested = {version: requested_version.version,
                 revision_comments: requested_version.revision_comments.presence,
                 created_at: requested_version.created_at,
                 updated_at: requested_version.updated_at
    }


    requested
  end

  has_many :content_blobs do
    v = @scope[:requested_version]
    if v.nil?
      v = object.version
    end

    requested_version = object.find_version(v)

    [requested_version.content_blob]

  end

end
