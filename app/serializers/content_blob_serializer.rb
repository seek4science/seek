class ContentBlobSerializer < BaseSerializer
   attributes :original_filename, :url, :md5sum, :content_type
  attribute :is_remote do
    object.file_exists?
  end

   def self_link
     polymorphic_path([object.asset,object])
   end

end
