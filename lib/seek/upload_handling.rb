module Seek
  module UploadHandling
    include Seek::MimeTypes

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
    rescue RestClient::ResourceNotFound, SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH
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
      blob_params = content_blob_params
      blob_params = update_params_for_batch(blob_params)
      allow_empty_content_blob = model_image_present?
      return false unless check_for_data_or_url(blob_params) unless allow_empty_content_blob
      blob_params = arrayify_params(blob_params)
      blob_params.each do |item_params|
        return false unless check_for_data_or_url(item_params) unless allow_empty_content_blob
        return false unless check_for_empty_data_if_present(item_params)
        return false unless check_for_valid_uri_if_present(item_params)
        return false unless check_for_valid_scheme(item_params)

        if add_from_upload?(item_params)
          return false unless process_upload(item_params)
        else
          return false unless process_from_url(item_params)
        end
      end

      params[:content_blob] = blob_params
      clean_params
    end

    def model_image_present?
      !params[:model_image].nil? && !params[:model_image][:image_file].nil?
    end

    def create_content_blobs
      asset = eval "@#{controller_name.downcase.singularize}"
      version = asset.version

      content_blob_params.each do |item_params|
        # MERGENOTE - move this to the upload handing and param manipulation during tidying up
        content_type = item_params[:content_type] || content_type_from_filename(item_params[:original_filename])
        attributes = { tmp_io_object: item_params[:tmp_io_object],
                       url: item_params[:data_url],
                       external_link: !item_params[:make_local_copy] == '1',
                       original_filename: item_params[:original_filename],
                       content_type: content_type,
                       asset_version: version }
        if asset.respond_to?(:content_blobs)
          asset.content_blobs.create(attributes)
        else
          asset.create_content_blob(attributes)
        end

      end
      retain_previous_content_blobs(asset)
    end

    def retain_previous_content_blobs(asset)
      retained_ids = retained_content_blob_ids
      if retained_ids.present? && (previous_version = asset.find_version(asset.version - 1))
        previous_version.content_blobs.select { |blob| retained_ids.include?(blob.id) }.each do |blob|
          new_blob = asset.content_blobs.build(url: blob.url,
                                               original_filename: blob.original_filename,
                                               content_type: blob.content_type,
                                               asset_version: asset.version)
          FileUtils.cp(blob.filepath, new_blob.filepath) if File.exist?(blob.filepath)
          # need to save after copying the file, coz an after_save on contentblob relies on the file
          new_blob.save

        end
      end
    end

    def content_type_from_filename(filename)
      if filename.nil?
        'text/html' # assume it points to a webpage if there is no filename
      else
        file_format = filename.split('.').last.try(:strip)
        possible_mime_types = mime_types_for_extension file_format
        type = possible_mime_types.sort.first || 'application/octet-stream'
        type
      end
    end

    def retained_content_blob_ids
      if params[:content_blobs] && params[:content_blobs][:id]
        params[:content_blobs][:id].keys.map { |id| id.to_i }.sort
      else
        []
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
          @error_msg = 'Nothing can be found at that URL. Please check the address and try again'
        else
          @error = true
          @error_msg = "We can't find out information about this URL - unhandled response code: #{code}"
      end
    end

    def arrayify_params(blob_params)
      result = []
      Array(blob_params[:data_url]).each.with_index do |url, i|
        unless url.blank?
          result << { data_url: url,
                      original_filename: Array(blob_params[:original_filename])[i],
                      make_local_copy: Array(blob_params[:make_local_copy])[i] }
        end

      end
      Array(blob_params[:data]).each do |data|
        unless data.blank?
          result << { data: data }
        end
      end
      result
    end

    def handle_exception_response(exception)
      case exception
        when Seek::Exceptions::InvalidSchemeException, URI::InvalidURIError
          @error = true
          @error_msg = 'The URL appears to be invalid'
        else
          fail exception
      end
    end

    def process_upload(blob_params)
      blob_params[:content_type] = (blob_params[:data]).content_type
      blob_params[:original_filename] = (blob_params[:data]).original_filename if blob_params[:original_filename].blank?
      blob_params[:tmp_io_object] = blob_params[:data]
    end

    def process_from_url(blob_params)
      @data_url = blob_params[:data_url]
      code = check_url_response_code(@data_url)
      make_local_copy = blob_params[:make_local_copy] == '1'

      # MERGENOTE, FIXME: An external link is not the same as the reverse of a local copy. An external link is not nessarily desirable for a non copied URL that has been registered, but for now we will keep this behaviour
      @external_link = !make_local_copy
      case code
        when 200
          headers = fetch_url_headers(@data_url)
          filename = determine_filename_from_disposition(headers[:content_disposition])
          filename ||= determine_filename_from_url(@data_url)
          if make_local_copy
            downloader = RemoteDownloader.new
            data_hash = downloader.get_remote_data @data_url, nil, nil, nil, make_local_copy
            blob_params[:tmp_io_object] = File.open data_hash[:data_tmp_path], 'r'
          end
          blob_params[:content_type] = (extract_mime_content_type(headers[:content_type]) || '')
          blob_params[:original_filename] = filename || ''
        when 401, 403
          blob_params[:content_type] = ''
          blob_params[:original_filename] = ''
        else
          flash.now[:error] = "Processing the URL responded with a response code (#{code}), indicating the URL is inaccessible."
          return false
      end
      true
    end

    def add_from_upload?(blob_params)
      !blob_params[:data].blank?
    end

    def init_asset_for_render
      clean_params
      c     = controller_name.singularize
      obj = c.camelize.constantize.new(asset_params)
      eval "@#{c} = obj"
    end

    def clean_params
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

    def check_for_data_or_url(blob_params)
      if (blob_params[:data]).blank? && (blob_params[:data_url]).blank?
        if blob_params.include?(:data_url)
          flash.now[:error] = 'Please select a file to upload or provide a URL to the data.'
        else
          flash.now[:error] = 'Please select a file to upload.'
        end
        false
      else
        true
      end
    end

    def check_for_empty_data_if_present(blob_params)
      return true unless blob_params[:data_url].blank?
      Array(blob_params[:data]).each do |data|
        if !data.blank? && data.size == 0
          flash.now[:error] = 'The file that you are uploading is empty. Please check your selection and try again!'
          return false
        end
      end
      true
    end

    def check_for_valid_scheme(blob_params)
      if !blob_params[:data_url].blank? && !valid_scheme?(blob_params[:data_url])
        flash.now[:error] = "The URL type is invalid, only URLs of type #{VALID_SCHEMES.map { |s| "#{s}" }.join', '} are valid"
        false
      else
        true
      end
    end

    def valid_uri?(uri)
      uri.try(:strip) =~ /\A#{URI.regexp}\z/
    end

    def check_for_valid_uri_if_present(blob_params)
      if !blob_params[:data_url].blank? && !valid_uri?(blob_params[:data_url])
        flash.now[:error] = "The URL '#{blob_params[:data_url]}' is not valid"
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
      filename = nil
      if valid_uri?(url)
        path = URI.parse(url).path
        filename = path.split('/').last unless path.nil?
        filename = filename.strip unless filename.nil?
      end
      filename
    end

    def asset_params
      params[controller_name.downcase.singularize.to_sym]
    end

    def content_blob_params
      params[:content_blob]
    end

    def update_params_for_batch(params)
      data = []
      data_urls = []
      original_filenames = []
      make_local_copy = []
      params.keys.map { |k| k }.sort.each do |k|
      if k.to_s =~ /data_\d{1,2}\z/
        val = params.delete(k)
        data << val unless val.blank?
      elsif k.to_s =~ /data_url_\d{1,2}\z/
        url = params.delete(k)
        k = k.to_s.gsub('data_url', 'original_filename')
        filename = params.delete(k.to_sym)
        k = k.gsub('original_filename', 'make_local_copy')
        copy = params.delete(k.to_sym)
        unless url.strip.blank?
          original_filenames << filename
          data_urls << url
          make_local_copy << copy
        end
      end

    end

      params[:data] = data unless data.empty?
      params[:data_url] = data_urls unless data_urls.empty?
      params[:original_filename] = original_filenames unless data_urls.empty?
      params[:make_local_copy] = make_local_copy unless data_urls.empty?
      params
  end
  end

  module Exceptions
    class InvalidSchemeException < Exception; end
  end
end
