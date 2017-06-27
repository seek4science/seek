module Seek
  module UploadHandling
    module DataUpload
      include Seek::UploadHandling::ParameterHandling
      include Seek::UploadHandling::ContentInspection

      def handle_upload_data
        blob_params = params[:content_blobs]
        allow_empty_content_blob = model_image_present?

        unless allow_empty_content_blob || retained_content_blob_ids.present?
          if !blob_params || blob_params.empty? || blob_params.none? { |p| check_for_data_or_url(p) }
            flash.now[:error] ||= 'Please select a file to upload or provide a URL to the data.'
            return false
          end
        end

        blob_params.select! { |p| !(p[:data].blank? && p[:data_url].blank?) }

        blob_params.each do |item_params|
          return false unless allow_empty_content_blob || check_for_data_or_url(item_params)

          if add_from_upload?(item_params)
            return false unless add_data_for_upload(item_params)
          else
            return false unless add_data_for_url(item_params)
          end
        end

        true
      end

      def add_data_for_upload(item_params)
        return false unless check_for_empty_data_if_present(item_params)
        process_upload(item_params)
      end

      def add_data_for_url(item_params)
        default_to_http_if_missing(item_params)
        return false unless check_for_valid_uri_if_present(item_params)
        return false unless check_for_valid_scheme(item_params)
        process_from_url(item_params)
      end

      def create_content_blobs
        asset = eval "@#{controller_name.downcase.singularize}"
        version = asset.version

        unless model_image_present? && params[:content_blobs].blank?
          content_blobs_params.each do |item_params|
            attributes = build_attributes_hash_for_content_blob(item_params, version)
            if asset.respond_to?(:content_blobs)
              asset.content_blobs.create(attributes)
            else
              asset.create_content_blob(attributes)
            end
          end
        end
        retain_previous_content_blobs(asset)
      end

      def build_attributes_hash_for_content_blob(item_params, version)
        { tmp_io_object: item_params[:tmp_io_object],
          url: item_params[:data_url],
          external_link: !item_params[:make_local_copy] == '1',
          original_filename: item_params[:original_filename],
          content_type: item_params[:content_type],
          make_local_copy: item_params[:make_local_copy] == '1',
          file_size: item_params[:file_size],
          asset_version: version }
      end

      def retain_previous_content_blobs(asset)
        retained_ids = retained_content_blob_ids
        previous_version = asset.find_version(asset.version - 1)
        if retained_ids.present? && previous_version
          retained_blobs = previous_version.content_blobs.select { |blob| retained_ids.include?(blob.id) }
          retained_blobs.each do |blob|
            copy_blob_to_asset(asset, blob)
          end
        end
      end

      def copy_blob_to_asset(asset, blob)
        new_blob = asset.content_blobs.build(url: blob.url,
                                             original_filename: blob.original_filename,
                                             content_type: blob.content_type,
                                             asset_version: asset.version)
        FileUtils.cp(blob.filepath, new_blob.filepath) if File.exist?(blob.filepath)
        # need to save after copying the file, coz an after_save on contentblob relies on the file
        new_blob.save
      end

      def process_upload(blob_params)
        data = blob_params[:data]
        blob_params.delete(:data_url)
        blob_params.delete(:original_filename)
        blob_params[:original_filename] = data.original_filename
        blob_params[:tmp_io_object] = data
        blob_params[:content_type] = data.content_type || content_type_from_filename(blob_params[:original_filename])
      end

      def process_from_url(blob_params)
        @data_url = blob_params[:data_url]
        blob_params.delete(:data)
        info = {}
        case URI(@data_url).scheme
        when 'http', 'https'
          handler = Seek::DownloadHandling::HTTPHandler.new(@data_url)
          info = handler.info
          unless [200, 401, 403].include?(info[:code])
            flash.now[:error] = "Processing the URL responded with a response code (#{info[:code]}), indicating the URL is inaccessible."
            return false
          end
        when 'ftp'
          handler = Seek::DownloadHandling::FTPHandler.new(@data_url)
          info = handler.info
        end

        blob_params[:original_filename] = info[:file_name] || ''
        blob_params[:content_type] = info[:content_type]
        blob_params[:file_size] = info[:file_size]
        blob_params[:headers] = info

        true
      end

      # whether there is data being uploaded rather than a URI being registered
      def add_from_upload?(blob_params)
        !blob_params[:data].blank?
      end

      def handle_upload_data_failure
        if render_new?
          respond_to do |format|
            format.html do
              render action: :new
            end
          end
        end
      end

      # if the urls misses the schema, default to http
      def default_to_http_if_missing(blob_params)
        url = blob_params[:data_url]
        unless url.blank?
          begin
            blob_params[:data_url] = Addressable::URI.heuristic_parse(url).to_s
          rescue Addressable::URI::InvalidURIError
            blob_params[:data_url] = url
          end
        end
      end

      def check_for_valid_scheme(blob_params)
        if !blob_params[:data_url].blank? && !valid_scheme?(blob_params[:data_url])
          flash.now[:error] = "The URL type is invalid, URLs with the scheme: #{INVALID_SCHEMES.map { |s| "#{s}" }.join ', '} are not permitted."
          false
        else
          true
        end
      end

      def render_new?
        action_name == 'create'
      end
    end
  end
end
