module Seek
  module UploadHandling
    VALID_SCHEMES = %w(http https ftp)
    def valid_scheme?(url)
      uri = URI.encode((url || '').strip)
      scheme = URI.parse(uri).scheme
      VALID_SCHEMES.include?(scheme)
    end

    def check_url_response_code(url)
      RestClient.head(url).code
    rescue RestClient::MethodNotAllowed
      405
    # FIXME: catching SocketError and Errno::ECONNREFUSED is a temporary hack, unable to resovle url and connect is not the same as a 404
    rescue RestClient::ResourceNotFound, SocketError,Errno::ECONNREFUSED
      404
    rescue RestClient::InternalServerError
      500
    rescue RestClient::Forbidden
      403
    rescue RestClient::Unauthorized
      401
    end

    def content_is_webpage?(content_type)
      extract_mime_content_type(content_type) == 'text/html'
    end

    def extract_mime_content_type(content_type)
      return nil if content_type.nil?
      # remove charset, e.g. "text/html; charset=UTF-8"
      raw_type = content_type.split(';')[0] || ''
      raw_type = raw_type.strip.downcase
    end

    def fetch_url_headers(url)
      RestClient.head(url, accept: :html).headers
    end

    def summarize_webpage(url)
      MetaInspector.new(url, allow_redirections: true)
    end

    def process_view_for_successful_url(url)
      headers = fetch_url_headers(url)
      @content_type = headers[:content_type]
      @size = headers[:content_length]
      @size_mb = @size.to_i / 10_000
      if content_is_webpage?(@content_type)

        @is_webpage = true
        page = summarize_webpage(url)
        @title = page.title
        @description = page.description
        @image = page.image
        @image ||= page.images[0] unless page.images.blank?
      else
        @is_webpage = false
        @filename = determine_filename_from_disposition(headers[:content_disposition])
        @filename ||= determine_filename_from_url(url)
      end
    end

    def handle_upload_data
      asset_params = asset_params(params)
      asset_params = update_params_for_batch(asset_params)

      return false unless validate_params(asset_params)
      asset_params = arrayify_params(asset_params)
      asset_params.each do |item_params|

        return false unless check_for_empty_data_if_present(item_params)
        return false unless check_for_valid_uri_if_present(item_params)
        return false unless check_for_valid_scheme(item_params)

        if add_from_upload?(item_params)
          return false unless process_upload(item_params)
        else
          return false unless process_from_url(item_params)
        end
      end

      clean_params
      params[:content_blob]=asset_params
    end

    def create_content_blobs
      asset = eval "@#{self.controller_name.downcase.singularize}"
      version = asset.version

      content_blob_params = asset_params(params)
      content_blob_params.each do |item_params|
        content_type = item_params[:content_type] || content_type_from_filename(item_params[:original_filename])
        asset.create_content_blob(:tmp_io_object => item_params[:tmp_io_object],
                                      :url=>item_params[:data_url],
                                      :external_link=>!item_params[:make_local_copy]=="1",
                                      :original_filename=>item_params[:original_filename],
                                      :content_type=>content_type,
                                      :asset_version=>version
            )
      end
    end

    def handle_non_200_response(code)
      case code
        when 403
          @unauthorized = true
        when 405
          @error = true
          @error_msg = "We can't find out information about this URL - Method not allowed response."
        when 404
          @error = true
          @error_msg = "Nothing can be found at that URL. Please check the address and try again"
        else
          @error = true
          @error_msg = "We can't find out information about this URL - unhandled response code: #{code}"
      end
    end

    def arrayify_params asset_params
      result = []
      Array(asset_params[:data_url]).each.with_index do |url,i|
        unless url.blank?
          result << {:data_url=>url,
                     :original_filename=>Array(asset_params[:original_filename])[i],
                     :make_local_copy=>Array(asset_params[:make_local_copy])[i]}
        end

      end
      Array(asset_params[:data]).each do |data|
        unless data.blank?
          result << {:data=>data}
        end
      end
      result
    end

    def handle_exception_response(exception)
      case exception
        when Seek::Exceptions::InvalidSchemeException, URI::InvalidURIError
          @error=true
          @error_msg="The URL appears to be invalid"
        else
          raise exception
      end
    end

    def process_upload(asset_params)
      asset_params[:content_type] = (asset_params[:data]).content_type
      asset_params[:original_filename] = (asset_params[:data]).original_filename if asset_params[:original_filename].blank?
      asset_params[:tmp_io_object] = asset_params[:data]
    end

    def process_from_url(asset_params)
      @data_url = asset_params[:data_url]
      code = check_url_response_code(@data_url)
      make_local_copy = asset_params[:make_local_copy]=="1"

      #MERGENOTE, FIXME: An external link is not the same as the reverse of a local copy. An external link is not nessarily desirable for a non copied URL that has been registered, but for now we will keep this behaviour
      @external_link = !make_local_copy
      case code
        when 200
          headers = fetch_url_headers(@data_url)
          filename = determine_filename_from_disposition(headers[:content_disposition])
          filename ||= determine_filename_from_url(@data_url)
          if make_local_copy
            downloader = RemoteDownloader.new
            data_hash = downloader.get_remote_data @data_url, nil, nil, nil, make_local_copy
            asset_params[:tmp_io_object] = File.open data_hash[:data_tmp_path], 'r'
          end
          asset_params[:content_type] = (extract_mime_content_type(headers[:content_type]) || '')
          asset_params[:original_filename] = filename || ""
        when 401, 403
          asset_params[:content_type]=""
          asset_params[:original_filename]=""
        else
          flash.now[:error] = "Processing the URL responded with a response code (#{code}), indicating the URL is inaccessible."
          return false
      end
      true
    end

    def add_from_upload?(asset_params)
      !asset_params[:data].blank?
    end

    def init_asset_for_render
      clean_params
      c     = controller_name.singularize
      obj = c.camelize.constantize.new(asset_params(params))
      eval "@#{c} = obj"
    end

    def clean_params
      asset_params = asset_params(params)
      %w(data_url data make_local_copy).each do |key|
        asset_params.delete(key)
      end
    end

    def handle_upload_data_failure
      if render_new?
        init_asset_for_render
        respond_to do |format|
          format.html do
            render action: :new
          end
        end
      end
    end

    def render_new?
      action_name == 'create'
    end

    def validate_params(asset_params)
      if (asset_params[:data]).blank? && (asset_params[:data_url]).blank?
        if asset_params.include?(:data_url)
          flash.now[:error] = 'Please select a file to upload or provide a URL to the data.'
        else
          flash.now[:error] = 'Please select a file to upload.'
        end
        false
      else
        true
      end
    end

    def check_for_empty_data_if_present(asset_params)
      return true unless asset_params[:data_url].blank?
      Array(asset_params[:data]).each do |data|
        if !data.blank? && data.size == 0
          flash.now[:error] = 'The file that you are uploading is empty. Please check your selection and try again!'
          return false
        end
      end
      true
    end

    def check_for_valid_scheme(asset_params)
      if !asset_params[:data_url].blank? && !valid_scheme?(asset_params[:data_url])
        flash.now[:error] = "The URL type is invalid, only URLs of type #{VALID_SCHEMES.map { |s| "#{s}" }.join', '} are valid"
        false
      else
        true
      end
    end

    def valid_uri?(uri)
      uri.try(:strip) =~ /\A#{URI.regexp}\z/
    end

    def check_for_valid_uri_if_present(asset_params)
      if !asset_params[:data_url].blank? && !valid_uri?(asset_params[:data_url])
        flash.now[:error] = "The URL '#{asset_params[:data_url]}' is not valid"
        false
      else
        true
      end
    end

    def determine_filename_from_disposition(disposition)
      disposition ||= ''
      Mechanize::HTTP::ContentDispositionParser.parse(disposition).try(:filename)
    end

    def determine_filename_from_url(url)
      filename=nil
      if valid_uri?(url)
        path = URI.parse(url).path
        filename = path.split("/").last unless path.nil?
        filename = filename.strip unless filename.nil?
      end
      filename
    end

    def asset_params(params)
      params[:content_blob]
    end

    def update_params_for_batch(params)
      data=[]
      data_urls = []
      params.keys.collect{|k| k}.sort.each do |k|
        if k.to_s =~ /data_\d{1,2}\z/
          val = params.delete(k)
          data << val unless val.blank?
        elsif k.to_s =~ /data_url_\d{1,2}\z/
          val = params.delete(k)
          data_urls << val unless val.strip.blank?
        end
      end
      params[:data]=data unless data.empty?
      params[:data_url]=data_urls unless data_urls.empty?
      params
    end
  end

  module Exceptions
    class InvalidSchemeException < Exception; end
  end
end
