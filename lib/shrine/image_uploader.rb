require "image_processing/mini_magick"

class Shrine
  class ImageUploader < Shrine
    plugin :derivation_endpoint, prefix: "derivations/image" # matches mount point

    derivation :thumbnail do |file, width|
      ImageProcessing::MiniMagick
        .source(file)
        .convert('png')
        .resize(width)
        .call
    end
  end
end