module Seek
  module ContentBlobCommon
    def handle_download disposition='attachment', image_size=nil
      if @content_blob.url.blank?
        if @content_blob.file_exists?
          if image_size && @content_blob.is_image?
            @content_blob.copy_image
            @content_blob.resize_image(image_size)
            filepath = @content_blob.full_cache_path(image_size)
            headers["Content-Length"]=File.size(filepath).to_s
          else
            filepath = @content_blob.filepath
            #added for the benefit of the tests after rails3 upgrade - but doubt it is required
            headers["Content-Length"]=@content_blob.filesize.to_s
          end
          send_file filepath, :filename => @content_blob.original_filename, :type => @content_blob.content_type || "application/octet-stream", :disposition => disposition
        else
          redirect_on_error @asset_version,"Unable to find a copy of the file for download, or an alternative location. Please contact an administrator of #{Seek::Config.application_name}."
        end
      else
        begin
          if @asset_version.contributor.nil? #A jerm generated resource
            download_jerm_asset
          else
            download_via_url
          end
        rescue Seek::DownloadException=>de
          redirect_on_error @asset_version,"There was an error accessing the remote resource, and a local copy was not available. Please try again later when the remote resource may be available again."
        rescue Jerm::JermException=>de
          redirect_on_error @asset_version,de.message
        end

      end
    end

    def return_file_or_redirect_to redirected_url=nil, error_message = nil
      if @content_blob.file_exists?
        send_file @content_blob.filepath, :filename => @content_blob.original_filename, :type => @content_blob.content_type, :disposition => 'attachment'
      else
        flash[:error]= error_message if error_message
        redirect_to redirected_url
      end
    end

    def download_jerm_asset
      project = @asset_version.projects.first
      project.decrypt_credentials
      downloader=Jerm::DownloaderFactory.create project.title
      resource_type = @asset_version.class.name.split("::")[0] #need to handle versions, e.g. Sop::Version
      begin
        data_hash = downloader.get_remote_data @content_blob.url,project.site_username,project.site_password, resource_type
        send_file data_hash[:data_tmp_path], :filename => data_hash[:filename] || @content_blob.original_filename, :type => data_hash[:content_type] || @content_blob.content_type, :disposition => 'attachment'
      rescue Seek::DownloadException,Jerm::JermException=>de

        puts "Unable to fetch from remote: #{de.message}"
        if @content_blob.file_exists?
          send_file @content_blob.filepath, :filename => @content_blob.original_filename, :type => @content_blob.content_type, :disposition => 'attachment'
        else
          raise de
        end
      end
    end

    def download_via_url
      code = url_response_code(@content_blob.url)
      if code == "200"
        downloader=Seek::RemoteDownloader.new
        begin
          data_hash = downloader.get_remote_data @content_blob.url
          filename = get_filename data_hash[:filename], @content_blob.original_filename
          send_file data_hash[:data_tmp_path], :filename => filename, :type => data_hash[:content_type] || @content_blob.content_type, :disposition => 'attachment'
        rescue Exception=>e
          error_message = "There is a problem downloading this file. #{e}"
          redirected_url = polymorphic_path(@asset_version.parent,{:version=>@asset_version.version})
          return_file_or_redirect_to redirected_url, error_message
        end
      elsif (["301","302","401"].include?(code))
        return_file_or_redirect_to @content_blob.url
      elsif code=="404"
        error_message = "This item is referenced at a remote location, which is currently unavailable"
        redirected_url = polymorphic_path(@asset_version.parent,{:version=>@asset_version.version})
        return_file_or_redirect_to redirected_url, error_message
      else
        error_message = "There is a problem downloading this file."
        redirected_url = polymorphic_path(@asset_version.parent,{:version=>@asset_version.version})
        return_file_or_redirect_to redirected_url, error_message
      end
    end
  end



end
