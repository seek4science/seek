module Seek
  module Samples
    # Class to handle the extraction and temporary storage of samples from a data file
    class Extractor

      TTL = 1.week # Time to store the cache of extracted samples

      def initialize(data_file, sample_type)
        @data_file = data_file
        @sample_type = sample_type
      end

      def extract
        cache { @data_file.extract_samples(@sample_type) }
      end

      def persist
        samples = extract # Re-extracts samples if cache expired, otherwise returns the cached samples

        samples.each(&:save)
      end

      private

      def cache_key
        "extracted-samples-#{@data_file.id}-#{@sample_type.id}"
      end

      def cache(&block)
        Rails.cache.fetch(cache_key, expires_in: TTL) { block.call }
      end

    end
  end
end
