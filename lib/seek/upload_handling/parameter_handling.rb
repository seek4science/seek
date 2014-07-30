module Seek
  module UploadHandling
    module ParameterHandling
      def asset_params
        params[controller_name.downcase.singularize.to_sym]
      end

      def content_blob_params
        params[:content_blob]
      end

      def clean_params
        if asset_params
          %w(data_url data make_local_copy).each do |key|
            asset_params.delete(key)
          end
        end
      end

      def arrayify_params(blob_params)
        result = []
        Array(blob_params[:data_url]).each.with_index do |url, index|
          unless url.blank?
            result << { data_url: url,
                        original_filename: Array(blob_params[:original_filename])[index],
                        make_local_copy: Array(blob_params[:make_local_copy])[index] }
          end

        end
        Array(blob_params[:data]).each do |data|
          unless data.blank?
            result << { data: data }
          end
        end
        result
      end

      def update_params_for_batch(params)
        data = []
        data_urls = []
        original_filenames = []
        make_local_copy = []
        params.keys.sort.each do |key|
          key_str = key.to_s
          if key_str.to_s =~ /data_\d{1,2}\z/
            val = params.delete(key)
            data << val unless val.blank?
          elsif key_str.to_s =~ /data_url_\d{1,2}\z/
            url = params.delete(key)
            key = key_str.gsub('data_url', 'original_filename')
            filename = params.delete(key.to_sym)
            key = key.gsub('original_filename', 'make_local_copy')
            copy = params.delete(key.to_sym)
            unless url.strip.blank?
              original_filenames << filename
              data_urls << url
              make_local_copy << copy
            end
          end

        end

        params[:data] = data unless data.empty?

        unless data_urls.empty?
          params[:data_url] = data_urls
          params[:original_filename] = original_filenames
          params[:make_local_copy] = make_local_copy
        end

        params
      end

      def retained_content_blob_ids
        content_blobs = params[:content_blobs]
        if content_blobs && content_blobs[:id]
          content_blobs[:id].keys.map { |id| id.to_i }.sort
        else
          []
        end
      end

      def model_image_present?
        params[:model_image] && params[:model_image][:image_file]
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

      def check_for_valid_uri_if_present(blob_params)
        data_url_param = blob_params[:data_url]
        if !data_url_param.blank? && !valid_uri?(data_url_param)
          flash.now[:error] = "The URL '#{data_url_param}' is not valid"
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
    end
  end
end
