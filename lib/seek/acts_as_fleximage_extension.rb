module Seek
  module ActsAsFleximageExtension
    MAX_SIZE = 1500
    STANDARD_SIZE = 900

    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def acts_as_fleximage_extension
        include Seek::ActsAsFleximageExtension::InstanceMethods
      end
    end

    module InstanceMethods
      def resize_image(size = STANDARD_SIZE)
        size = filter_size size
        unless cache_exists?(size) # look in file system cache before attempting db access
          # resize (keeping image side ratio), encode and cache the picture
          operate do |image|
            Rails.logger.info "resizing to #{size}"
            image.resize size, upsample: true
            image_binary = image.image.to_blob
            # cache data
            cache_data!(image_binary, size)
          end
        end
      end

      # caches data (where size = #{size}x#{size})
      def cache_data!(image_binary, size = nil)
        FileUtils.mkdir_p(cache_directory(size))
        File.open(full_cache_path(size), 'wb+') { |f| f.write(image_binary) }
      end

      def cache_directory(size = nil)
        if self.is_a?(ContentBlob)
          path = Seek::Config.temporary_filestore_path + '/image_assets'
        elsif self.is_a?(Avatar)
          path = Seek::Config.temporary_filestore_path + '/avatars'
        elsif self.is_a?(ModelImage)
          path = Seek::Config.temporary_filestore_path + '/model_images'
        end

        if size
          size = filter_size size
          path = "#{path}/#{size}"
        end

        path
      end

      def full_cache_path(size = nil)
        path = cache_directory(size)
        if self.class.respond_to?(:image_storage_format) && self.class.respond_to?(:image_storage_format_default)
          path = "#{path}/#{id}.#{self.class.image_storage_format}"
        else
          path = "#{path}/#{id}.png"
        end
        path
      end

      def cache_exists?(size = nil)
        File.exist?(full_cache_path(size))
      end

      def filter_size(size)
        size = size[0..-(Regexp.last_match(1).length.to_i + 2)] if size =~ /[0-9]+x[0-9]+\.([a-z0-9]+)/ # trim file extension
        max_size = MAX_SIZE
        matches = size.match(/([0-9]+)x([0-9]+).*/)
        if matches
          width = matches[1].to_i
          height = matches[2].to_i
          width = max_size if width > max_size
          height = max_size if height > max_size
          return "#{width}x#{height}"
        else
          matches = size.match(/([0-9]+)/)
          if matches
            width = matches[1].to_i
            width = max_size if width > max_size
            return "#{width}"
          else
            return STANDARD_SIZE
          end
        end
      end

      def width
        if self.respond_to?(:image_width)
          image_width
        elsif File.exist?(full_cache_path)
          Magick::Image.read(full_cache_path).first.try(:columns)
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Seek::ActsAsFleximageExtension
end
