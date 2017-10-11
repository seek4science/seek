class ContributedResourceSerializer < PCSSerializer
  attributes :title, :description, :license

  attribute :version, key: :latest_version

  attribute :versions do
    versions_data = []
    object.versions.each do |v|
      versions_data.append({version: v.version,
                            revision_comments: v.revision_comments.presence})
    end
    versions_data
  end

  def get_version
  v = @scope[:requested_version]
  if v.nil?
    v = object.version
  end

  object.find_version(v)
  end

   attribute :version do
     get_version.version
  end

  attribute :revision_comments do
    get_version.revision_comments.presence
  end

  attribute :created_at do
    get_version.created_at
    end
  attribute :updated_at do
    get_version.updated_at
  end

 has_many :content_blobs do
   v = @scope[:requested_version]
   if v.nil?
     v = object.version
   end

   requested_version = object.find_version(v)

   blobs = []
    if defined?(requested_version.content_blobs)
      requested_version.content_blobs.each do |cb|
        blobs.append(cb)
      end
    elsif defined?(requested_version.content_blob)
      blobs.append(requested_version.content_blob)
    end
    blobs
 end

end
