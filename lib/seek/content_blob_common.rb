module Seek
  module ContentBlobCommon

    def download_jerm_asset content_blob
      asset_version = content_blob.asset.find_version(content_blob.asset_version)
      project=asset_version.projects.first
      project.decrypt_credentials
      downloader=Jerm::DownloaderFactory.create project.name
      resource_type = asset_version.class.name.split("::")[0] #need to handle versions, e.g. Sop::Version
      begin
        data_hash = downloader.get_remote_data content_blob.url,project.site_username,project.site_password, resource_type
        send_file data_hash[:data_tmp_path], :filename => data_hash[:filename] || content_blob.original_filename, :type => data_hash[:content_type] || content_blob.content_type, :disposition => 'attachment'
      rescue Seek::DownloadException=>de
        #FIXME: use proper logging
        puts "Unable to fetch from remote: #{de.message}"
        if content_blob.file_exists?
          send_file content_blob.filepath, :filename => content_blob.original_filename, :type => content_blob.content_type, :disposition => 'attachment'
        else
          raise de
        end
      end
    end

    def download_via_url content_blob
      asset_version = content_blob.asset.find_version(content_blob.asset_version)
      code = url_response_code(content_blob.url)
      if code == "200"
        downloader=RemoteDownloader.new
        begin
          data_hash = downloader.get_remote_data content_blob.url
          send_file data_hash[:data_tmp_path], :filename => data_hash[:filename] || content_blob.original_filename, :type => data_hash[:content_type] || content_blob.content_type, :disposition => 'attachment'
        rescue Exception=>e
          error_message = "There is a problem downloading this file. #{e}"
          redirected_url = polymorphic_path(asset_version.parent,{:version=>asset_version.version})
          return_file_or_redirect_to content_blob, redirected_url, error_message
        end
      elsif (["302","401"].include?(code))
        return_file_or_redirect_to content_blob, content_blob.url
      elsif code=="404"
        error_message = "This item is referenced at a remote location, which is currently unavailable"
        redirected_url = polymorphic_path(asset_version.parent,{:version=>asset_version.version})
        return_file_or_redirect_to content_blob,  redirected_url, error_message
      else
        error_message = "There is a problem downloading this file."
        redirected_url = polymorphic_path(asset_version.parent,{:version=>asset_version.version})
        return_file_or_redirect_to content_blob,  redirected_url, error_message
      end
    end

    def handle_download content_blob, disposition='attachment'
      asset_version = content_blob.asset.find_version(content_blob.asset_version)
      if content_blob.url.blank?
        if content_blob.file_exists?
          send_file content_blob.filepath, :filename => content_blob.original_filename, :type => content_blob.content_type, :disposition => disposition
        else
          redirect_on_error asset_version,"Unable to find a copy of the file for download, or an alternative location. Please contact an administrator of #{Seek::Config.application_name}."
        end
      else
        begin
          if asset_version.contributor.nil? #A jerm generated resource
            download_jerm_asset content_blob
          else
            if content_blob.file_exists?
              send_file content_blob.filepath, :filename => content_blob.original_filename, :type => content_blob.content_type, :disposition => disposition
            else
              download_via_url content_blob
            end
          end
        rescue Seek::DownloadException=>de
          redirect_on_error asset_version,"There was an error accessing the remote resource, and a local copy was not available. Please try again later when the remote resource may be available again."
        rescue Jerm::JermException=>de
          redirect_on_error asset_version,de.message
        end

      end
    end

    private
    def return_file_or_redirect_to content_blob, redirected_url=nil, error_message = nil
      if content_blob.file_exists?
          send_file content_blob.filepath, :filename => content_blob.original_filename, :type => content_blob.content_type, :disposition => 'attachment'
      else
          flash[:error]= error_message if error_message
          redirect_to redirected_url
      end
    end
  end
end
