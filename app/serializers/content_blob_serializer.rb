class ContentBlobSerializer < BaseSerializer
  attributes :original_filename, :url, :md5sum, :sha1sum, :content_type

  def self_link
    polymorphic_path([object.asset, object])
  end
end
