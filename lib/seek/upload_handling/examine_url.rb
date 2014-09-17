module Seek
  module UploadHandling
    module ExamineUrl
      include Seek::UploadHandling::ContentInspection

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

      def handle_exception_response(exception)
        case exception
          when URI::InvalidURIError
            @error = true
            @error_msg = 'The URL appears to be invalid'
          else
            fail exception
        end
      end
    end
  end
end
