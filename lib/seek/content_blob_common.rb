module Seek
  module ContentBlobCommon
    def self.included(base)
      base.before_filter :set_content_blob, :only=>[:get_pdf]
      base.before_filter :set_asset_version, :only=>[:get_pdf]
    end

    def set_content_blob
      begin
        @content_blob = ContentBlob.find(params[:content_blob_id])
      rescue ActiveRecord::RecordNotFound
        error("Unable to find content blob", "is invalid")
        return false
      end
    end

    def set_asset_version
      begin
        @asset_version = @content_blob.asset.find_version(@content_blob.asset_version)
      rescue Exception=>e
        error("Unable to find asset version", "is invalid")
        return false
      end
    end

    def view_pdf_content
      #param code is used for temporary link
      asset = eval("@#{self.controller_name.singularize}")
      get_pdf_url = polymorphic_path(asset, :content_blob_id => params[:content_blob_id], :action => 'get_pdf', :code => params[:code])
      render :partial => 'layouts/pdf_content_display', :locals => {:get_pdf_url => get_pdf_url }
    end

    def get_pdf
      if @content_blob.url.blank?
        if File.exists?(@content_blob.filepath)
          pdf_or_convert
        else
          redirect_on_error @asset_version,"Unable to find a copy of the file for viewing, or an alternative location. Please contact an administrator of #{Seek::Config.application_name}."
        end
      else
        begin
          if @asset_version.contributor.nil? #A jerm generated resource
            get_and_process_file(false, true)  #from jerm
          else
            get_and_process_file(true, false)  #from url
          end
        rescue Seek::DownloadException=>de
          redirect_on_error @asset_version,"There was an error accessing the remote resource, and a local copy was not available. Please try again later when the remote resource may be available again."
        rescue Jerm::JermException=>de
          redirect_on_error @asset_version,de.message
        end
      end
    end

    #check whether the file is pdf, otherwise convert to pdf
    #then return the pdf file
    def pdf_or_convert dat_filepath=@content_blob.filepath
      file_path_array = dat_filepath.split('.')
      pdf_filepath = file_path_array.take(file_path_array.length - 1).join('.') + '.pdf'
      if @content_blob.is_pdf?
        send_file dat_filepath, :filename => @content_blob.original_filename, :type => @content_blob.content_type, :disposition => 'attachment'
      else
        @content_blob.convert_to_pdf(dat_filepath,pdf_filepath)

        if File.exists?(pdf_filepath)
          send_file pdf_filepath, :filename => @content_blob.original_filename, :type => @content_blob.content_type, :disposition => 'attachment'
        else
          redirect_on_error @asset_version, 'Unable to convert the file for display'
        end
      end
    end

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

    def get_and_process_file from_url=true,from_jerm=false
      if from_url
        data_hash = get_data_hash_from_url
      else
        data_hash = get_data_hash_from_jerm
      end

      if data_hash
        pdf_or_convert data_hash[:data_tmp_path]
      elsif File.exists?(@content_blob.filepath)
        pdf_or_convert
      else
        redirect_on_error @asset_version,"Unable to find a copy of the file for viewing, or an alternative location. Please contact an administrator of #{Seek::Config.application_name}."
      end
    end

    def get_data_hash_from_url
      code = url_response_code(@content_blob.url)
      if code == "200"
        downloader=RemoteDownloader.new
        begin
          data_hash = downloader.get_remote_data @content_blob.url
          data_hash
        rescue Exception=>e
          nil
        end
      end
    end

    def get_data_hash_from_jerm
      project=@asset_version.projects.first
      project.decrypt_credentials
      downloader=Jerm::DownloaderFactory.create project.name
      resource_type = @asset_version.class.name.split("::")[0] #need to handle versions, e.g. Sop::Version
      begin
        data_hash = downloader.get_remote_data @content_blob.url,project.site_username,project.site_password, resource_type
        data_hash
      rescue Seek::DownloadException=>de
        nil
      end
    end
  end
end
