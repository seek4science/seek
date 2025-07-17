module Seek

    module DataFiles
  
      class FetchException < StandardError; end
  
      # Class to handle the extraction and temporary storage of samples from a data file
      class Unzipper
        def initialize(data_file)
          @data_file = data_file
        end
  
        # Unzip datafiles and store in the filesystem temporarily
        def unzip
          self.class.decode(cache { self.class.encode(@data_file.unzip(tmp_file_path)) })
        end
  
        # Persist the extracted datafiles to the database
        def persist(user = User.current_user)
          User.with_current_user(user) do
            data_files = unzip.select(&:valid?) # Re-unzips datafiles if cache expired, otherwise returns the cached datafiles
  
            if data_files.any?
              DataFile.transaction do
                last_id = DataFile.last.try(:id) || 0

                data_files.each do |data_file|
                  data_file_content_blob = ContentBlob.new
                  file_path = Dir["#{tmp_file_path}/**/#{data_file.title}"][0]

                  File.open(file_path) do |file|
                    data_file_content_blob.tmp_io_object = file
                    data_file_content_blob.original_filename = data_file.title.to_s
                    data_file_content_blob.save
                    data_file.content_blob = data_file_content_blob
                    data_file.policy = data_file.zip_origin.policy.deep_copy
                    data_file.save
                  end
                end
  
                project_ids = data_files.first.project_ids
                contributor = data_files.first.contributor
                # to get the created files. There is a very small potential of picking up files created from an overlapping process but it will just trigger some additional jobs
                data_files = DataFile.where(title: data_files.collect(&:title), contributor: contributor).where(
                  'id > ?', last_id
                )
                # makes sure linked resources are updated
                data_files.each do |data_file|
                  data_file.project_ids = project_ids
                  data_file.run_callbacks(:validation) { false }
                end
                ReindexingQueue.enqueue(data_files)
                AuthLookupUpdateQueue.enqueue(data_files)
              end
            end
            data_files
          end
        end
  
        # Clear the temporarily-stored datafiles
        def clear
          File.delete(cache_path) if File.exist?(cache_path)
          FileUtils.rm_r(tmp_file_path) if File.exist?(tmp_file_path)
        end
  
        # Return the temporarily-stored datafiles if they exist (nil if not)
        def fetch
          self.class.decode(cache)
        rescue ArgumentError=>exception
          raise FetchException.new(exception.message)
        end
  
        private
  
        def cache_path
          "#{cache_key}-metadata"
        end

        def tmp_file_path
          "#{cache_key}-files/"
        end
  
        def cache_key
          "#{Seek::Config.temporary_filestore_path}/unzipped-datafiles-#{@data_file.id}"
        end

        def cache(&block)
          if File.exist?(cache_path) & Dir.exist?(tmp_file_path)
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
              (value['id'] ? DataFile.find(value['id']) : DataFile.new).tap do |d|
                d.assign_attributes(value)
              end
            end
          end
        end
      end
    end
  end
  