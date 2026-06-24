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

        # Yields a guaranteed local filesystem path to the archive. On local storage this is the
        # on-disk path; on S3 the object is streamed to a temp copy that is removed afterwards.
        # Archive libraries below require a real local file, so every outermost read goes through here.
        def with_archive_path(&block)
          content_blob.with_temporary_copy(&block)
        end

        def unzip_zip(tmp_dir)
          with_archive_path { |path| Seek::Util.unzip(path, tmp_dir) }
        end

        # When +input+ is given (an already-decompressed stream from unzip_tgz/tbz2/txz) it is used
        # directly. When omitted, the archive is a plain tar and is streamed to a local temp copy.
        def unzip_tar(tmp_dir, input = nil)
          if input
            Minitar.unpack(input, tmp_dir)
          else
            with_archive_path { |path| Minitar.unpack(path, tmp_dir) }
          end
        end

        def unzip_tbz2(tmp_dir)
          Tempfile.create('decompressed_tar') do |temp_tar|
            with_archive_path do |path|
              Bzip2::FFI::Reader.open(path) do |reader|
                IO.copy_stream(reader, temp_tar)
              end
            end
            temp_tar.rewind
            unzip_tar(tmp_dir, temp_tar)
          end
        end

        def unzip_tgz(tmp_dir)
          with_archive_path do |path|
            Zlib::GzipReader.open(path) do |unzip_folder|
              unzip_tar(tmp_dir, unzip_folder)
            end
          end
        end

        def unzip_txz(tmp_dir)
          #This should work according to documentation but Buffer unusable error when trying to read the stream for large files
          #Seems to work fine for smaller files (<6MB) but not consitent error (e.g large empty txt file succeeded)
          #content_type_detection turned off until fixed
          with_archive_path do |path|
            XZ::StreamReader.open(path) do |stream|
              unzip_tar(tmp_dir, stream)
            end
          end
        end

        def unzip_7z(tmp_dir)
          with_archive_path do |path|
            SevenZipRuby::Reader.open_file(path).extract_all(tmp_dir)
          end
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
