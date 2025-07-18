module Seek
    module DataFiles
      module Unzip
  
        def unzip(tmp_dir)
          #Unzip given folder and extract all files to tmp_dir
          #Does not recursively unzip compressed files
          FileUtils.rm_r(tmp_dir) if File.exist?(tmp_dir)
          Dir.mkdir(tmp_dir)
          if content_blob.is_zip?
            unzip_zip(tmp_dir)
          elsif content_blob.is_tgz?
            unzip_tgz(tmp_dir)
          elsif content_blob.is_tbz2?
            unzip_tbz2(tmp_dir)
          elsif content_blob.is_txz?
            unzip_txz(tmp_dir)
          elsif content_blob.is_tar?
            unzip_tar(tmp_dir)
          elsif content_blob.is_7zip?
            unzip_7z(tmp_dir)
          end
          find_unzipped_datafiles(tmp_dir)
        end
  
        def unzip_zip(tmp_dir)
          Zip::File.open(content_blob.filepath).entries.each do |file|
            path = File.join(tmp_dir, file.name)
            FileUtils.mkdir_p(File.dirname(path))
            file.extract(path) unless File.exist?(path)
          end
        end

        def unzip_tar(tmp_dir, input = content_blob.filepath)
            Minitar.unpack(input, tmp_dir)
        end

        def unzip_tbz2(tmp_dir)
          Tempfile.create('decompressed_tar') do |temp_tar|
            Bzip2::FFI::Reader.open(content_blob.filepath) do |reader|
              IO.copy_stream(reader, temp_tar)
            end
            temp_tar.rewind
            unzip_tar(tmp_dir, temp_tar)
          end
        end
  
        def unzip_tgz(tmp_dir)
          Zlib::GzipReader.open(content_blob.filepath)  do |unzip_folder|
            unzip_tar(tmp_dir, unzip_folder)
          end
        end
        
        def unzip_txz(tmp_dir)
          #This should work according to documentation but Buffer unusable error when trying to read the stream for large files
          #Seems to work fine for smaller files (<6MB) but not consitent error (e.g large empty txt file succeeded)
          #content_type_detection turned off until fixed
          XZ::StreamReader.open(content_blob.filepath) do |stream|
            unzip_tar(tmp_dir, stream)
          end
        end
  
        def unzip_7z(tmp_dir)
          SevenZipRuby::Reader.open_file(content_blob.filepath).extract_all(tmp_dir)
        end

        def find_unzipped_datafiles(tmp_dir)
          unzipped = []
          #move one level down the directory so that zip folder name isn't included in all filenames
          if Dir["#{tmp_dir}*/"].length == 1
            tmp_dir = Dir["#{tmp_dir}*/"][0]
          end
          Dir["#{tmp_dir}**/*"].each do |entry|
            if File.file?(entry)
              file_name = entry.split(tmp_dir)[1]
              unzipped << save_unzipped_datafile(file_name)
            end
          end
          unzipped
        end
  
        def save_unzipped_datafile(file_name)
          data_file_params = {
            title: file_name,
            license: license,
            projects: projects,
            description: '',
            contributor_id: contributor.id,
            zip_origin_id: self.id
          }
          DataFile.new(data_file_params)
        end
      end
    end
  end
