class ContentBlobSerializer < BaseSerializer
   attributes :original_filename, :url, :md5sum, :content_type
  attribute :is_remote do
    object.file_exists?
  end

end
