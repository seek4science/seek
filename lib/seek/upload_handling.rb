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
    # FIXME: catching SocketError is a temporary hack, unable to resovle url and connect is not the same as a 404
    rescue RestClient::ResourceNotFound, SocketError
      404
    rescue RestClient::InternalServerError
      500
    rescue RestClient::Forbidden
      403
    rescue RestClient::Unauthorized
      401
    end

    def content_is_webpage?(content_type)
      content_type ||= ''
      # remove charset, e.g. "text/html; charset=UTF-8"
      raw_type = content_type.split(';')[0] || ''
      raw_type = raw_type.strip.downcase
      raw_type == 'text/html'
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
      end
    end

    def handle_upload_data
      asset_params = asset_params(params)
      return false unless validate_params(asset_params)
      return false unless check_for_empty_data_if_present(asset_params)
      return false unless check_for_valid_uri_if_present(asset_params)
      return false unless check_for_valid_scheme(asset_params)
      if add_from_upload?(asset_params)
        return false unless process_upload(asset_params)
      else
        return false unless process_from_url(asset_params)
      end
      clean_params
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

    def process_upload(asset_params)
      asset_params[:content_type] = (asset_params[:data]).content_type
      asset_params[:original_filename] = (asset_params[:data]).original_filename if asset_params[:original_filename].blank?
      @tmp_io_object = asset_params[:data]
    end

    def process_from_url(asset_params)
      @data_url = asset_params[:data_url]
      code = check_url_response_code(@data_url)
      make_local_copy = asset_params[:make_local_copy]=="1"

      #MERGENOTE, FIXME: An external link is not the same as the reverse of a local copy. An external link is not nessarily desirable for a non copied URL that has been registered, but for now we will keep this behaviour
      @external_link = !make_local_copy
      case code
        when 200
          # FIXME: refactor this, the downloader is only being used to make a local copy and get the original filename
          downloader = RemoteDownloader.new
          data_hash = downloader.get_remote_data @data_url, nil, nil, nil, make_local_copy

          @tmp_io_object = File.open data_hash[:data_tmp_path], 'r' if make_local_copy

          asset_params[:content_type] = (data_hash[:content_type] || "")
          asset_params[:original_filename] = (data_hash[:filename] || "") if asset_params[:original_filename].blank?
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
      if !(asset_params[:data]).blank? && (asset_params[:data]).size == 0 && (asset_params[:data_url]).blank?
        flash.now[:error] = 'The file that you are uploading is empty. Please check your selection and try again!'
        false
      else
        true
      end
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
      uri =~ /\A#{URI.regexp}\z/
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

    def asset_params(params)
      params[symbol_for_controller]
    end

    def symbol_for_controller
      c = controller_name.downcase
      c.singularize.to_sym
    end
  end

  module Exceptions
    class InvalidSchemeException < Exception; end
  end
end
