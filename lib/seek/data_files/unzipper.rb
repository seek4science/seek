module Seek

    module DataFiles
  
      class FetchException < StandardError; end
  
      # Class to handle the extraction and temporary storage of samples from a data file
      class Unzipper
        def initialize(data_file)
          @data_file = data_file
        end
  
        # Unzip datafiles and store in the filesystem temporarily
        def unzip(overwrite = false)
          self.class.decode(cache { self.class.encode(@data_file.unzip(overwrite, tmp_file_path, confirm=false)) })
        end
  
  
        # Clear the temporarily-stored samples
        def clear
          File.delete(cache_path) if File.exist?(cache_path)
          FileUtils.rm_r(tmp_file_path) if File.exist?(tmp_file_path)
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
          "unzipped-datafiles-#{@data_file.id}"
        end

        def tmp_file_path
          tmp_dir = "#{Rails.root}/tmp/#{cache_key}/"
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
              (value['id'] ? DataFile.find(value['id']) : DataFile.new).tap do |d|
                d.assign_attributes(value)
              end
            end
          end
        end
      end
    end
  end
