class ContentBlobSerializer < BaseSerializer
  attributes :original_filename, :url, :md5sum, :sha1sum, :content_type

  attribute :size do
    object.file_size
  end

  has_one :asset, polymorphic: true

  link(:self) { polymorphic_path([object.asset, object]) }
  link(:download) { polymorphic_path([:download, object.asset, object]) }
end
