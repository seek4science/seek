module Seek
  module ContentBlobCommon
    def self.included(base)
      base.before_filter :set_content_blob, :only=>[:get_pdf]
    end

    def set_content_blob
      begin
        @content_blob = ContentBlob.find(params[:content_blob_id])
      rescue ActiveRecord::RecordNotFound
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
        if File.exists?(dat_filepath)
          pdf_or_convert
        else
          redirect_on_error asset_version,"Unable to find a copy of the file for download, or an alternative location. Please contact an administrator of #{Seek::Config.application_name}."
        end
      else
        begin
          if asset_version.contributor.nil? #A jerm generated resource
            download_jerm_asset @content_blob if @content_blob.is_pdf?
          else
            download_via_url @content_blob if @content_blob.is_pdf?
          end
        rescue Seek::DownloadException=>de
          redirect_on_error asset_version,"There was an error accessing the remote resource, and a local copy was not available. Please try again later when the remote resource may be available again."
        rescue Jerm::JermException=>de
          redirect_on_error asset_version,de.message
        end
      end
    end

    #check whether the file is pdf, otherwise convert to pdf
    #then return the pdf file
    def pdf_or_convert @content_blob
      dat_filepath = @content_blob.filepath
      pdf_filepath = @content_blob.filepath('pdf')
      asset_version = @content_blob.asset.find_version(@content_blob.asset_version)
      if @content_blob.is_pdf?
        send_file dat_filepath, :filename => @content_blob.original_filename, :type => @content_blob.content_type, :disposition => 'attachment'
      else
        @content_blob.convert_to_pdf

        if File.exists?(pdf_filepath)
          send_file pdf_filepath, :filename => @content_blob.original_filename, :type => @content_blob.content_type, :disposition => 'attachment'
        else
          redirect_on_error asset_version, 'Unable to convert the file for display'
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
      if (["302","401"].include?(code))
        redirect_to(content_blob.url,:target=>"_blank")
      elsif code=="404"
        flash[:error]="This item is referenced at a remote location, which is currently unavailable"
        redirect_to polymorphic_path(asset_version.parent,{:version=>asset_version.version})
      else
        downloader=RemoteDownloader.new
        data_hash = downloader.get_remote_data content_blob.url
        send_file data_hash[:data_tmp_path], :filename => data_hash[:filename] || content_blob.original_filename, :type => data_hash[:content_type] || content_blob.content_type, :disposition => 'attachment'
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
  end
end
