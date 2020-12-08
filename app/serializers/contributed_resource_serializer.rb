class ContributedResourceSerializer < PCSSerializer
  attributes :title, :description, :license

  attribute :version, key: :latest_version, if: -> { object.respond_to?(:version) }

  attribute :tags do
    serialize_annotations(object)
  end

  attribute :discussion_links do
    object.discussion_links.collect do |link|
      {id:link.id, label: link.label, url: link.url}
    end
  end

  attribute :versions, if: -> { object.respond_to?(:versions) } do
    versions_data = []
    object.versions.each do |v|
      path = polymorphic_path(object, version: v.version)
      versions_data.append(version: v.version,
                           revision_comments: v.revision_comments.presence,
                           url: "#{base_url}#{path}")
    end
    versions_data
  end

  attribute :version, if: -> { object.respond_to?(:version) } do
    version_number
  end

  attribute :revision_comments, if: -> { object.respond_to?(:version) } do
    get_version.revision_comments.presence
  end

  attribute :created_at do
    get_version.created_at
  end
  attribute :updated_at do
    get_version.updated_at
  end

  attribute :content_blobs, if: -> { object.respond_to?(:content_blobs) || object.respond_to?(:content_blob) } do
    requested_version = get_version

    if requested_version.respond_to?(:content_blobs)
      blobs = requested_version.content_blobs
    elsif requested_version.respond_to?(:content_blob)
      blobs = [requested_version.content_blob].compact
    else
      blobs = []
    end

    blobs.map { |cb| convert_content_blob_to_json(cb) }
  end

  attribute :other_creators

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
      polymorphic_path(object, version: version_number)
    else
      polymorphic_path(object)
    end
  end

  def get_version
    @version ||= object.respond_to?(:find_version) ? object.find_version(version_number) : object
  end

  private

  def version_number
    @scope[:requested_version] || object.try(:version)
  end
end
