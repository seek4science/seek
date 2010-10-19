module Seek
  module AssetsCommon
    
    #required to get the icon_filename_for_key
    include ImagesHelper
    
    def test_asset_url
      c = self.controller_name.downcase    
      symb=c.singularize.to_sym
      
      icon_filename=icon_filename_for_key("tick")
      begin
        asset_url=params[symb][:data_url]
        url = URI.parse(asset_url)
        Net::HTTP.start(url.host, url.port) do |http|
          code = http.head(url.request_uri).code
          puts code
          icon_filename=icon_filename_for_key("error") unless code == "200"
        end
        
      rescue Exception=>e
        puts e
        icon_filename=icon_filename_for_key("error")
      end
      
      respond_to do |format|
        #FIXME: path won't be safe it running under a subdirectory
        format.html { render :text=>"<img src='/images/#{icon_filename}'/>" }
      end
      
    end
    
    def download_jerm_asset asset
      project=asset.project
      project.decrypt_credentials
      downloader=Jerm::DownloaderFactory.create project.name
      resource_type = resource.class.name.split("::")[0] #need to handle versions, e.g. Sop::Version
      data_hash = downloader.get_remote_data asset.content_blob.url,project.site_username,project.site_password, resource_type
      send_data data_hash[:data], :filename => data_hash[:filename] || resource.original_filename, :content_type => data_hash[:content_type] || asset.content_type, :disposition => 'attachment'
    end
    
    def download_via_url asset    
      downloader=Jerm::HttpDownloader.new
      data_hash = downloader.get_remote_data asset.content_blob.url
      send_data data_hash[:data], :filename => data_hash[:filename] || asset.original_filename, :content_type => data_hash[:content_type] || asset.content_type, :disposition => 'attachment'
    end
    
    def handle_data    
      c = self.controller_name.downcase    
      symb=c.singularize.to_sym
      
      if (params[symb][:data]).blank? && (params[symb][:data_url]).blank?
        respond_to do |format|
          flash.now[:error] = "Please select a file to upload or provide a URL to the data."
          format.html do 
            set_parameters_for_sharing_form
            render :action => "new"
          end
        end
        return false
      elsif !(params[symb][:data]).blank? && (params[symb][:data]).size == 0 && (params[symb][:data_url]).blank?
        respond_to do |format|
          flash.now[:error] = "The file that you are uploading is empty. Please check your selection and try again!"
          format.html do 
            set_parameters_for_sharing_form
            render :action => "new"
          end
        end
        return false
      else
        #upload takes precendence if both params are present
        if !(params[symb][:data]).blank?
          # store properties and contents of the file temporarily and remove the latter from params[],
          # so that when saving main object params[] wouldn't contain the binary data anymore
          params[symb][:content_type] = (params[symb][:data]).content_type
          params[symb][:original_filename] = (params[symb][:data]).original_filename
          @data = params[symb][:data].read
        elsif !(params[symb][:data_url]).blank?
          make_local_copy = params[symb][:local_copy]=="1"
          @data_url=params[symb][:data_url]
          downloader=Jerm::HttpDownloader.new
          data_hash = downloader.get_remote_data @data_url,nil,nil,nil,make_local_copy
          @data=data_hash[:data] if make_local_copy
          params[symb][:content_type] = data_hash[:content_type]
          params[symb][:original_filename] = data_hash[:filename]
        else
          raise Exception.new("Neither a data file or url was provided.")        
        end
        
        params[symb].delete 'data_url'
        params[symb].delete 'data'
        params[symb].delete 'local_copy' 
        return true
      end
    end  
    
    def handle_download asset
      if asset.content_blob.url.blank?
      if asset.content_blob.file_exists?
        send_file asset.content_blob.filepath, :filename => asset.original_filename, :content_type => asset.content_type, :disposition => 'attachment'
      else
        send_data asset.content_blob.data, :filename => asset.original_filename, :content_type => asset.content_type, :disposition => 'attachment'  
      end      
    else
      if asset.contributor.nil? #A jerm generated resource
        download_jerm_resource asset
      else
        if asset.content_blob.file_exists?
          send_file asset.content_blob.filepath, :filename => asset.original_filename, :content_type => asset.content_type, :disposition => 'attachment'
        else
          download_via_url asset
        end
      end
    end
    end
    
  end
end