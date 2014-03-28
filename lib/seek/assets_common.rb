require 'seek/annotation_common'

module Seek
  module AssetsCommon
    require 'net/ftp'

    include Seek::AnnotationCommon
    #required to get the icon_filename_for_key
    include ImagesHelper

    #this is required to initialise the @<model> (e.g. @sop), before re-rendering the :new page
    def init_asset_for_render params                                                            
        c     = self.controller_name.singularize                                                  
        model = c.camelize.constantize                                                            
        symb  =c.to_sym                                                                           
        params[symb].delete 'data_url'                                                            
        params[symb].delete 'data'                                                                
        params[symb].delete 'local_copy'                                                          
        obj=model.new params[symb]                                                                
        eval "@#{c.singularize} = obj"                                                            
    end
    
    def url_response_code asset_url
      url = URI.parse(URI.encode(asset_url.strip))
      code=""
      begin
        if (["http","https"].include?(url.scheme))
          http =  Net::HTTP.new(url.host, url.port)
          http.use_ssl=true if url.scheme=="https"
          http.start do |http|
            code = http.head(url.request_uri).code        
          end
        elsif (url.scheme=="ftp")        
          username = 'anonymous'
          password = nil
          username, password = url.userinfo.split(/:/) if url.userinfo
          
          ftp = Net::FTP.new(url.host)
          ftp.login(username,password)
          ftp.getbinaryfile(url.path, '/dev/null', 20) { break }
          ftp.close
          code="200"                       
        else
          raise Seek::IncompatibleProtocolException.new("Only http, https and ftp protocols are supported")  
        end
      rescue Net::FTPPermError
        code="401"       
      rescue Errno::ECONNREFUSED,SocketError,Errno::EHOSTUNREACH
        #FIXME:also using 404 for uknown host, which wouldn't actually really be a http response code
        #indicating that using response codes is not the best approach here.
        code="404" 
      end
      
      return code
    end
    
    def test_asset_url
      c = self.controller_name.downcase
      symb= params[:symb].nil?? c.singularize.to_sym : params[:symb].to_sym
      
      icon_filename=icon_filename_for_key("error")
      code=""
      msg=""
      asset_url=  params[:symb].nil?? params[symb][:data_url] : params[symb].values.first
      begin        
        code = url_response_code(asset_url)        
        if code == "200"
          icon_filename=icon_filename_for_key("tick")
          msg="The URL was accessed successfully"
        elsif code == "302" || code == "301"
          icon_filename=icon_filename_for_key("warn")
          msg="The url responded with a <b>redirect</b>. It can still be used, but if adding a url to a resource, the content type and filename may not be recorded.<br/>You will also not be able to make a copy. When a user downloads this file, they will be redirected to the URL."
        elsif code == "401"
          icon_filename=icon_filename_for_key("warn")
          msg="The url responded with <b>unauthorized</b>.<br/> It can still be used, but content type and filename will not be recorded.<br/>You will also not be able to make a copy. When a user downloads this file, they will be redirected to the URL."
        elsif code == "404"
          msg="Nothing was found at the URL you provided. You can test the link by opening in another window or tab:<br/><a href=#{asset_url} target='_blank'>#{asset_url}</a>"
        else
          msg="There was a problem accessing the URL. You can test the link by opening in another window or tab:<br/><a href=#{asset_url} target='_blank'>#{asset_url}</a>"
        end        
      rescue Seek::IncompatibleProtocolException=>e
        msg = e.message
      rescue Exception=>e        
        msg="There was a problem accessing the URL. You can test the link by opening in another window or tab:<br/><a href=#{asset_url}>#{asset_url}</a>"
      end
      
      image = "<img src='/assets/#{icon_filename}'/>"
      render :update do |page|
        page.replace_html "test_url_result_icon",image
        if msg.length>0
          page.replace_html "test_url_msg",msg
          page.show 'test_url_msg'
          page.visual_effect :highlight,"test_url_msg"
          if code=="200"
            page['local_copy'].enable
          else
            page['local_copy'].checked=false
            page['local_copy'].disable
          end
        end
      end
    end
    
    def handle_data render_action_on_error=:new
      #FIXME: too many nested if,else and rescue blocks. This method needs refactoring.
      c = self.controller_name.downcase    
      symb=c.singularize.to_sym
      
      if (params[symb][:data]).blank? && (params[symb][:data_url]).blank?
        flash.now[:error] = "Please select a file to upload or provide a URL to the data."
        if render_action_on_error
          init_asset_for_render params
          respond_to do |format|
            format.html do 
              render :action => render_action_on_error
            end
          end
        end
        return false
      elsif !(params[symb][:data]).blank? && (params[symb][:data]).size == 0 && (params[symb][:data_url]).blank?
        flash.now[:error] = "The file that you are uploading is empty. Please check your selection and try again!"
        if render_action_on_error
          init_asset_for_render params
          respond_to do |format|          
            format.html do 
              render :action => render_action_on_error
            end
          end
        end
        return false
      else
        #upload takes precedence if both params are present
        begin
          if !(params[symb][:data]).blank?
            # store properties and contents of the file temporarily and remove the latter from params[],
            # so that when saving main object params[] wouldn't contain the binary data anymore
            params[symb][:content_type] = (params[symb][:data]).content_type
            params[symb][:original_filename] = (params[symb][:data]).original_filename if params[symb][:original_filename].blank?
            @tmp_io_object = params[symb][:data]
          elsif !(params[symb][:data_url]).blank?
            make_local_copy = (params[symb][:local_copy]=="1")
            @data_url=params[symb][:data_url]
            code = url_response_code @data_url
            if (code == "200")
              downloader=RemoteDownloader.new
              data_hash = downloader.get_remote_data @data_url,nil,nil,nil,make_local_copy
              
              @tmp_io_object=File.open data_hash[:data_tmp_path],"r" if make_local_copy
              
              params[symb][:content_type] = data_hash[:content_type]
              params[symb][:original_filename] = data_hash[:filename] if params[symb][:original_filename].blank?
            elsif (["301","302","401"].include?(code))
              params[symb][:content_type] = ""
              params[symb][:original_filename] = ""
            else
              flash.now[:error] = "Processing the URL responded with a response code (#{code}), indicating the URL is inaccessible."
              if render_action_on_error
                init_asset_for_render params
                respond_to do |format|                  
                  format.html do 
                    render :action => render_action_on_error
                  end
                end
              end
              return false
            end            
          end
        rescue Seek::IncompatibleProtocolException=>e          
          flash.now[:error] = e.message
          if render_action_on_error
            init_asset_for_render params
            respond_to do |format|            
              format.html do 
                render :action => render_action_on_error
              end
            end
          end
          return false
        rescue Exception=>e
          flash.now[:error] = "Unable to read from the URL."
          if render_action_on_error
            init_asset_for_render params
            respond_to do |format|            
              format.html do 
                render :action => render_action_on_error
              end
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

    def redirect_on_error asset,msg=nil
      flash[:error]=msg if !msg.nil?
      if (asset.class.name.include?("::Version"))
        redirect_to asset.parent,:version=>asset.version
      else
        redirect_to asset
      end
    end

    def find_display_asset asset=eval("@#{self.controller_name.singularize}");
      name = asset.class.name.underscore
      if asset
          #if no version is specified, show the latest version
          #otherwise, show the specified version, if (this version is correct for login and project member user or if (this is the latest version and the user doesn't login or is not project member')
          if params[:version]
            if asset.find_version(params[:version]).blank? || (!(User.logged_in_and_member?) && params[:version].to_i != asset.latest_version.version)
              error('This version is not available', "invalid route")
              return false
            else
              eval "@display_#{name} = asset.find_version(params[:version])"
            end
          else
            eval "@display_#{name} = asset.latest_version"
          end
        end
    end
  end
end
