module Seek
  module Samples
    # Class to handle the extraction and temporary storage of samples from a data file
    class Extractor

      TTL = 1.week # Time to store the cache of extracted samples

      def initialize(data_file, sample_type = nil)
        @data_file = data_file
        @sample_type = sample_type
      end

      def extract
        # Marshalling doesn't seem to work on AR objects, so we just extract the attributes into a hash and then
        # rebuild them on load
        self.class.decode(cache { self.class.encode(@data_file.extract_samples(@sample_type)) })
      end

      def persist
        samples = extract # Re-extracts samples if cache expired, otherwise returns the cached samples

        samples.each(&:save)
      end

      def fetch
        self.class.decode(cache)
      end

      private

      def development_cache_path
        "#{Seek::Config.temporary_filestore_path}/#{cache_key}"
      end

      def cache_key
        "extracted-samples-#{@data_file.id}"
      end

      def cache(&block)
        if Rails.env.development?
          if File.exist?(development_cache_path)
            Marshal.load(File.binread(development_cache_path))
          elsif block_given?
            File.open(development_cache_path, 'wb') do |f|
              v = block.call
              f.write(Marshal.dump(v))
              v
            end
          else
            nil
          end
        else
          Rails.cache.fetch(cache_key, &block)
        end
      end

      def self.encode(values)
        values.map(&:attributes)
      end

      def self.decode(values)
        if values
          values.map do |value|
            Sample.new.tap { |s| s.assign_attributes(value, without_protection: true) }
          end
        end
      end
    end
  end
end
