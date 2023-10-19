module Seek
  module Samples

    class FetchException < StandardError; end

    # Class to handle the extraction and temporary storage of samples from a data file
    class Extractor
      def initialize(data_file, sample_type = nil)
        @data_file = data_file
        @sample_type = sample_type
      end

      # Extract samples and store in the filesystem temporarily
      def extract(overwrite = false)
        # Marshalling doesn't seem to work on AR objects, so we just extract the attributes into a hash and then
        # rebuild them on load
        self.class.decode(cache { self.class.encode(@data_file.extract_samples(@sample_type, false, overwrite)) })
      end

      # Persist the extracted samples to the database
      def persist(user = User.current_user)
        User.with_current_user(user) do
          samples = extract.select(&:valid?) # Re-extracts samples if cache expired, otherwise returns the cached samples

          if samples.any?
            Sample.transaction do
              samples.each do |sample|
                sample.run_callbacks(:save) { false }
                sample.run_callbacks(:create) { false }
              end

              last_id = Sample.last.try(:id) || 0
              sample_type = samples.first.sample_type
              Sample.import(samples, validate: false, batch_size: 2000)
              SampleTypeUpdateJob.new(sample_type, false).queue_job

              contributor = samples.first.contributor
              # to get the created samples. There is a very small potential of picking up samples created from an overlapping process but it will just trigger some additional jobs
              samples = Sample.where(sample_type: sample_type, title: samples.collect(&:title), contributor: contributor).where(
                'id > ?', last_id
              )
              # makes sure linked resources are updated
              samples.each do |sample|
                sample.run_callbacks(:validation) { false }
              end
              ReindexingQueue.enqueue(samples)
              AuthLookupUpdateQueue.enqueue(samples)
            end
          end

          samples
        end
      end

      # Clear the temporarily-stored samples
      def clear
        File.delete(cache_path) if File.exist?(cache_path)
      end

      # Return the temporarily-stored samples if they exist (nil if not)
      def fetch
        self.class.decode(cache)
      rescue ArgumentError=>exception
        raise FetchException.new(exception.message)
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
          v = block.call
          File.open(cache_path, 'wb') do |f|
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
            (value['id'] ? Sample.find(value['id']) : Sample.new).tap do |s|
              s.assign_attributes(value)
            end
          end
        end
      end
    end
  end
end
