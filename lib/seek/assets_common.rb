module Seek
  module AssetsCommon
    
    #required to get the icon_filename_for_key
    include ImagesHelper
    
    def url_response_code asset_url
      url = URI.parse(asset_url)
      code=""
      Net::HTTP.start(url.host, url.port) do |http|
        code = http.head(url.request_uri).code        
      end
      return code
    end
    
    def test_asset_url
      c = self.controller_name.downcase
      symb=c.singularize.to_sym
      
      icon_filename=icon_filename_for_key("error")
      code=""
      msg=""
      begin
        asset_url=params[symb][:data_url]
        code = url_response_code(asset_url)        
        if code == "200"
          icon_filename=icon_filename_for_key("tick")
        elsif code == "302"
          icon_filename=icon_filename_for_key("warn")
          msg="The url responded with a redirect. It can still be used, but content type and filename will not be recorded.You will also not be able to store a copy."
        elsif code == "401"
          icon_filename=icon_filename_for_key("warn")
          "The url responded with a request for authorization. It can still be used, but content type and filename will not be recorded.You will also not be able to store a copy."
        end        
      rescue Exception=>e
        puts e
      end
      
      image = "<img src='/images/#{icon_filename}'/>"
      render :update do |page|
        page.replace_html "test_url_result_icon",image
        if msg.length>0
          page.replace_html "test_url_msg",msg
          page.show 'test_url_msg'
          page.visual_effect :highlight,"test_url_msg"
          page['local_copy'].checked=false
          page['local_copy'].disable
        else
          page.hide 'test_url_msg'
          page['local_copy'].enable
        end
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
        begin
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
          end        
        rescue Exception=>e
          respond_to do |format|
            flash.now[:error] = "Unable to process the URL"
            format.html do 
              set_parameters_for_sharing_form
              render :action => "new"
            end
          end
          return false
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