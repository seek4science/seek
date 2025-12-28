# lib/shrine/file_uploader.rb
require "shrine"

class Shrine

  class FileUploader < Shrine
    plugin :determine_mime_type
    plugin :restore_cached_data
    plugin :cached_attachment_data
  end

end