class ImageUploader < Shrine
  plugin :cached_attachment_data
end