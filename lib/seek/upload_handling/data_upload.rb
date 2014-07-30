module Seek
  module UploadHandling
    module DataUpload
      include Seek::UploadHandling::ParameterHandling
      include Seek::UploadHandling::ContentInspection

      def handle_upload_data
        blob_params = content_blob_params

        # MERGENOTE - the manipulation and validation of the params still needs a bit of cleaning up
        blob_params = update_params_for_batch(blob_params)
        allow_empty_content_blob = model_image_present?
        return false unless check_for_data_or_url(blob_params) unless allow_empty_content_blob || retained_content_blob_ids.present?
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
        true
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

      def process_upload(blob_params)
        blob_params[:content_type] = (blob_params[:data]).content_type
        blob_params[:original_filename] = (blob_params[:data]).original_filename if blob_params[:original_filename].blank?
        blob_params[:tmp_io_object] = blob_params[:data]
      end

      def process_from_url(blob_params)
        @data_url = blob_params[:data_url]
        code = check_url_response_code(@data_url)
        make_local_copy = blob_params[:make_local_copy] == '1'

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
        c = controller_name.singularize
        obj = c.camelize.constantize.new(asset_params)
        eval "@#{c} = obj"
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

      def check_for_valid_scheme(blob_params)
        if !blob_params[:data_url].blank? && !valid_scheme?(blob_params[:data_url])
          flash.now[:error] = "The URL type is invalid, only URLs of type #{VALID_SCHEMES.map { |s| "#{s}" }.join ', '} are valid"
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
