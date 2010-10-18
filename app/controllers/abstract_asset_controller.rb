class AbstractAssetController < ApplicationController
  
  def download_jerm_resource resource
    project=resource.project
    project.decrypt_credentials
    downloader=Jerm::DownloaderFactory.create project.name
    resource_type = resource.class.name.split("::")[0] #need to handle versions, e.g. Sop::Version
    data_hash = downloader.get_remote_data resource.content_blob.url,project.site_username,project.site_password, resource_type
    send_data data_hash[:data], :filename => data_hash[:filename] || resource.original_filename, :content_type => data_hash[:content_type] || resource.content_type, :disposition => 'attachment'
  end
  
  def download_via_url resource    
    downloader=Jerm::HttpDownloader.new
    data_hash = downloader.get_remote_data resource.content_blob.url
    send_data data_hash[:data], :filename => data_hash[:filename] || resource.original_filename, :content_type => data_hash[:content_type] || resource.content_type, :disposition => 'attachment'
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
    elsif !(params[symb][:data]).blank? && (params[symb][:data]).size == 0 && (params[symb][:data_url]).blank?
      respond_to do |format|
        flash.now[:error] = "The file that you are uploading is empty. Please check your selection and try again!"
        format.html do 
          set_parameters_for_sharing_form
          render :action => "new"
        end
      end
    else
      #upload takes precendence if both params are present
      if !(params[symb][:data]).blank?
        # store properties and contents of the file temporarily and remove the latter from params[],
        # so that when saving main object params[] wouldn't contain the binary data anymore
        params[symb][:content_type] = (params[symb][:data]).content_type
        params[symb][:original_filename] = (params[symb][:data]).original_filename
        @data = params[symb][:data].read
      elsif !(params[symb][:data_url]).blank?
        @data_url=params[symb][:data_url]
      else
        raise Exception.new("Neither a data file or url was provided.")        
      end
      
      params[symb].delete 'data_url'
      params[symb].delete 'data'      
      
    end
  end  
  
end