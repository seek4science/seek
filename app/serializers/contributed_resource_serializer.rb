class ContributedResourceSerializer < PCSSerializer
  attributes :title, :description, :license

  attribute :version, key: :latest_version

  attribute :versions do
    versions_data = []
    object.versions.each do |v|
      path = polymorphic_path(object,version:v.version)
      versions_data.append({version: v.version,
                            revision_comments: v.revision_comments.presence,
                           url: "#{base_url}#{path}"})
    end
    versions_data
  end

  attribute :version do
    version_number
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

  attribute :content_blobs do

    requested_version = get_version

    blobs = []
    if defined?(requested_version.content_blobs)
      requested_version.content_blobs.each do |cb|
        blobs.append(convert_content_blob_to_json(cb))
      end
    elsif defined?(requested_version.content_blob)
      blobs.append(convert_content_blob_to_json(requested_version.content_blob))
    end
    blobs
  end

  def convert_content_blob_to_json(cb)
    path = polymorphic_path([cb.asset, cb])
    {
        original_filename: cb.original_filename,
        url: cb.url,
        md5sum: cb.md5sum,
        sha1sum: cb.sha1sum,
        content_type: cb.content_type,
        link: "#{base_url}#{path}",
        size: cb.file_size
    }
  end

  def self_link
    if version_number
      polymorphic_path(object,version:version_number)
    else
      polymorphic_path(object)
    end
  end

  def get_version
    object.find_version(version_number)
  end

  private

  def version_number
    @scope[:requested_version] || object.try(:version)
  end


end
