class ContributedResourceSerializer < PCSSerializer
  attributes :title
  attribute :license, if: -> {object.respond_to?(:license)}
  attribute :description, if: -> {object.respond_to?(:description)}

  attribute :version, key: :latest_version, if: -> { object.respond_to?(:version) }

  attribute :tags do
    serialize_annotations(object, context ='tag')
  end

  attribute :versions, if: -> { object.respond_to?(:versions) } do
    versions_data = []
    object.visible_versions.each do |v|
      data = {
        version: v.version,
        revision_comments: v.revision_comments.presence,
        url: polymorphic_url(object, version: v.version, host: Seek::Config.site_base_host)
      }
      if v.is_git_versioned?
        data[:remote] = v.remote if v.remote?
        data[:commit] = v.commit
        data[:ref] = v.ref
        data[:tree] = polymorphic_path([object, :git_tree], version: v.version)
      end
      data[:doi]=v.doi if v.respond_to?(:doi) 
      versions_data.append(data)
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

  attribute :doi, if: -> { object.supports_doi? } do
    get_version.doi
  end

  def get_correct_blob_content(requested_version)
    blobs = if requested_version.respond_to?(:content_blobs)
              requested_version.content_blobs
            elsif requested_version.respond_to?(:content_blob)
              [requested_version.content_blob].compact
            else
              []
            end

    blobs.map { |cb| convert_content_blob_to_json(cb) }
  end

  attribute :content_blobs, if: -> { object.respond_to?(:content_blobs) || object.respond_to?(:content_blob) } do
    requested_version = get_version

    get_correct_blob_content(requested_version)
  end

  attribute :creators, if: -> { object.respond_to?(:assets_creators) } do
    serialize_assets_creators
  end

  attribute :other_creators

  def convert_content_blob_to_json(cb)
    {
      original_filename: cb.original_filename,
      url: cb.url,
      md5sum: cb.md5sum,
      sha1sum: cb.sha1sum,
      content_type: cb.content_type,
      link: polymorphic_url([cb.asset, cb]),
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
    @scope.try(:[],:requested_version) || object.try(:version)
  end

  def edam_annotations(property)
    terms = object.annotations_with_attribute(property, true).collect(&:value).sort_by(&:label)
    terms.collect do |term|
      {
        label: term.label,
        identifier: term.iri
      }
    end
  end
end
