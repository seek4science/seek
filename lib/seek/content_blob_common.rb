module Seek
  module ContentBlobCommon
    def download
      name = controller_name.singularize
      asset = instance_variable_get("@#{name}")
      asset_version = instance_variable_get("@display_#{name}")
      @asset_version = asset_version

      asset.just_used

      if asset.respond_to?(:openbis?) && asset.openbis?
        handle_openbis_download(asset, params[:perm_id])
      else
        content_blobs = if asset_version.respond_to?(:content_blobs)
                          asset_version.content_blobs
                        else
                          [asset_version.content_blob]
                        end

        has_image = asset_version.respond_to?(:model_image) && asset_version.model_image

        if content_blobs.length == 1 && !has_image
          download_single(content_blobs.first)
        elsif content_blobs.length > 1 || (content_blobs.length == 1 && has_image)
          downloadable_content_blobs = content_blobs.select(&:file_exists?)
          if downloadable_content_blobs.length == 1 && !has_image
            download_single(downloadable_content_blobs.first)
          elsif downloadable_content_blobs.length > 1 || (downloadable_content_blobs.length == 1 && has_image)
            handle_download_zip(asset_version)
          else
            redirect_on_error(asset, 'Cannot create zip file from remote content.')
          end
        else
          redirect_on_error(asset, 'No downloadable files found for this asset.')
        end
      end
    end

    def handle_openbis_download(asset, dataset_file_perm_id = nil)
      dataset = asset.openbis_dataset
      begin
        if dataset_file_perm_id
          dataset_file = dataset.dataset_files.detect { |f| f.file_perm_id == dataset_file_perm_id }
          raise 'No dataset file found for id' unless dataset_file
          dest = File.join(Seek::Config.temporary_filestore_path, "#{asset.id}-dataset_file-#{dataset_file.dataset_perm_id}-#{dataset_file.filename}")
          dataset_file.download(dest) unless File.exist?(dest)
          send_file dest, filename: dataset_file.filename, type: 'application/octet-stream', disposition: 'attachment'
        else
          dest_folder = File.join(Seek::Config.temporary_filestore_path, "#{asset.id}-dataset-#{dataset.perm_id}")
          zip_name = File.join(Seek::Config.temporary_filestore_path, "#{asset.id}-dataset-#{dataset.perm_id}.zip")
          dataset.download(dest_folder, zip_name, asset.title.underscore)
          send_file zip_name, filename: "#{dataset.perm_id}.zip", type: 'application/octet-stream', disposition: 'attachment'
        end
      rescue => e
        redirect_on_error(asset, "Cannot download file: #{e.message}")
      end
    end

    private

    # for assets that only have a single content-blob
    def download_single(content_blob)
      @content_blob = content_blob

      respond_to do |format|
        format.html { handle_download(params[:disposition] || 'attachment') }
      end
    end

    def handle_download_zip(asset_version)
      # get the list of filename and filepath, {:filename => filepath}
      files_to_download = {}
      # store content_type for the case of 1 file
      content_type = nil
      if asset_version.respond_to?(:model_image) && asset_version.model_image
        model_image = asset_version.model_image
        filename = check_and_rename_file files_to_download.keys, model_image.original_filename
        files_to_download[filename.to_s] = model_image.file_path
        content_type = model_image.content_type
      end
      asset_version.content_blobs.each do |content_blob|
        next unless File.exist? content_blob.filepath
        filename = check_and_rename_file files_to_download.keys, content_blob.original_filename
        files_to_download[filename.to_s] = content_blob.filepath
        content_type = content_blob.content_type
      end

      content_type ||= 'application/octet-stream'

      # making and sending zip file if there are more than one file
      if files_to_download.count > 1
        make_and_send_zip_file files_to_download, asset_version
      else
        filepath = files_to_download.values.first
        send_file filepath, filename: files_to_download.keys.first, type: content_type
        headers['Content-Length'] = File.size(filepath).to_s
      end
    end

    def make_and_send_zip_file(files_to_download, asset)
      zip_path = File.join(tmp_zip_file_dir, "#{Time.now.to_f}_#{asset.uuid}.zip")

      t = File.new(zip_path, 'w+')
      # Give the path of the temp file to the zip outputstream, it won't try to open it as an archive.
      Zip::OutputStream.open(t.path) do |zos|
        files_to_download.each do |filename, filepath|
          zos.put_next_entry(filename)
          zos.print IO.read(filepath)
        end
      end
      t.close

      send_file t.path, type: 'application/zip', disposition: 'attachment', filename: "#{asset.title}.zip"
      headers['Content-Length'] = File.size(t.path).to_s
    end

    def redirect_on_error(asset, msg = nil)
      flash[:error] = msg unless msg.nil?
      if asset.class.name.include?('::Version')
        redirect_to asset.parent, version: asset.version
      else
        redirect_to asset
      end
    end

    def handle_download(disposition = 'attachment', image_size = nil)
      if @content_blob.url.blank?
        if @content_blob.file_exists?
          if image_size && @content_blob.is_image?
            @content_blob.resize_image(image_size)
            filepath = @content_blob.full_cache_path(image_size)
            headers['Content-Length'] = File.size(filepath).to_s
          else
            filepath = @content_blob.filepath
            # added for the benefit of the tests after rails3 upgrade - but doubt it is required
            headers['Content-Length'] = @content_blob.file_size.to_s
          end
          send_file filepath, filename: @content_blob.original_filename, type: @content_blob.content_type || 'application/octet-stream', disposition: disposition
        else
          redirect_on_error @asset_version, "Unable to find a copy of the file for download, or an alternative location. Please contact an administrator of #{Seek::Config.instance_name}."
        end
      else
        begin
          if @asset_version.contributor.nil? # A jerm generated resource
            download_jerm_asset
          else
            case URI(@content_blob.url).scheme
            when 'ftp'
              stream_from_ftp_url
            else
              stream_from_http_url
            end

          end
        rescue Seek::DownloadException => de
          redirect_on_error @asset_version, 'There was an error accessing the remote resource, and a local copy was not available. Please try again later when the remote resource may be available again.'
        rescue Jerm::JermException => de
          redirect_on_error @asset_version, de.message
        end

      end
    end

    def download_jerm_asset
      project = @asset_version.projects.first
      downloader = Jerm::DownloaderFactory.create project.title
      resource_type = @asset_version.class.name.split('::')[0] # need to handle versions, e.g. Sop::Version
      begin
        data_hash = downloader.get_remote_data @content_blob.url, project.site_username, project.site_password, resource_type
        send_file data_hash[:data_tmp_path],
                  filename: data_hash[:filename] || @content_blob.original_filename,
                  type: data_hash[:content_type] || @content_blob.content_type,
                  disposition: 'attachment'
      rescue Seek::DownloadException, Jerm::JermException, SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH => de
        Rails.logger.info("Unable to fetch from remote: #{de.message}")
        if @content_blob.file_exists?
          send_file @content_blob.filepath,
                    filename: @content_blob.original_filename,
                    type: @content_blob.content_type,
                    disposition: 'attachment'
        else
          raise de
        end
      end
    end

    def stream_from_http_url
      info = Seek::DownloadHandling::HTTPHandler.new(@content_blob.url).info
      case info[:code]
      when 200
        stream_with(Seek::DownloadHandling::HTTPStreamer.new(@content_blob.url))
      when 401, 403
        # Try redirecting the user to the URL if SEEK cannot access it
        redirect_to @content_blob.url
      when 404
        error_message = 'This item is referenced at a remote location, which is currently unavailable'
        redirected_url = polymorphic_path(@asset_version.parent, version: @asset_version.version)
        return_file_or_redirect_to redirected_url, error_message
      else
        error_message = "There is a problem downloading this file. HTTP status code: #{info[:code]}"
        redirected_url = polymorphic_path(@asset_version.parent, { version: @asset_version.version })
        return_file_or_redirect_to redirected_url, error_message
      end
    end

    def stream_from_ftp_url
      stream_with(Seek::DownloadHandling::FTPStreamer.new(@content_blob.url))
    end

    def stream_with(streamer)
      response.headers['Content-Type'] ||= @content_blob.content_type
      response.headers['Content-Disposition'] = "attachment; filename=#{@content_blob.original_filename}"
      response.headers['Last-Modified'] = Time.now.ctime.to_s

      begin
        self.response_body = Enumerator.new do |yielder|
          streamer.stream do |chunk|
            yielder << chunk
          end
        end
      rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
             Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
        error_message = "There is a problem downloading this file. #{e}"
        redirected_url = polymorphic_path(@asset_version.parent, version: @asset_version.version)
        return_file_or_redirect_to redirected_url, error_message
      end
    end

    def return_file_or_redirect_to(redirected_url = nil, error_message = nil)
      if @content_blob.file_exists?
        send_file @content_blob.filepath, filename: @content_blob.original_filename, type: @content_blob.content_type, disposition: 'attachment'
      else
        flash[:error] = error_message if error_message
        redirect_to redirected_url
      end
    end

    def tmp_zip_file_dir
      dir = if Rails.env.test?
              File.join(Dir.tmpdir, 'seek-tmp', 'zip-files')
            else
              File.join(Rails.root, 'tmp', 'zip-files')
            end
      FileUtils.mkdir_p dir unless File.exist?(dir)
      dir
    end

    def check_and_rename_file(filename_list, filename)
      file = filename.split('.')
      file_format = file.last
      original_name = file.take(file.size - 1).join('.')
      i = 1
      while filename_list.include?(filename)
        filename = original_name + '_' + i.to_s + '.' + file_format
        i += 1
      end
      filename
    end
  end
end
