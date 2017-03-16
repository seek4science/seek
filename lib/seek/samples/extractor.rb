module Seek
  module Samples
    # Class to handle the extraction and temporary storage of samples from a data file
    class Extractor
      def initialize(data_file, sample_type = nil)
        @data_file = data_file
        @sample_type = sample_type
      end

      # Extract samples and store in the filesystem temporarily
      def extract
        # Marshalling doesn't seem to work on AR objects, so we just extract the attributes into a hash and then
        # rebuild them on load
        self.class.decode(cache { self.class.encode(@data_file.extract_samples(@sample_type)) })
      end

      # Persist the extracted samples to the database
      def persist
        samples = extract # Re-extracts samples if cache expired, otherwise returns the cached samples

        samples.each(&:save)
      end

      # Clear the temporarily-stored samples
      def clear
        File.delete(cache_path) if File.exist?(cache_path)
      end

      # Return the temporarily-stored samples if they exist (nil if not)
      def fetch
        self.class.decode(cache)
      end

      private

      def cache_path
        "#{Seek::Config.temporary_filestore_path}/#{cache_key}"
      end

      def cache_key
        "extracted-samples-#{@data_file.id}"
      end

      def cache(&block)
        if File.exist?(cache_path)
          Marshal.load(File.binread(cache_path))
        elsif block_given?
          File.open(cache_path, 'wb') do |f|
            v = block.call
            f.write(Marshal.dump(v))
            v
          end
                end
      end

      def self.encode(values)
        values.map do |value|
          value.attributes.merge(project_ids: value.project_ids) # Associations aren't included in `attributes`
        end
      end

      def self.decode(values)
        if values
          values.map do |value|
            Sample.new.tap { |s| s.assign_attributes(value) }
          end
        end
      end
    end
  end
end
