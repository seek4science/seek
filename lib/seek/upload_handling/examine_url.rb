module Seek
  module UploadHandling
    module ExamineUrl
      include Seek::UploadHandling::ContentInspection

      def handle_good_http_response(url, info)
        @content_type = info[:content_type]
        @size = info[:file_size]
        if content_is_webpage?(@content_type)
          @is_webpage = true
          page = summarize_webpage(url)
          @title = page.title
          @description = page.description
          @image = page.images.best
        else
          @is_webpage = false
          @filename = info[:file_name]
        end
      end

      def handle_good_ftp_response(_url, info)
        @is_webpage = false
        @size = info[:file_size]
        @content_type = info[:content_type]
        @filename = info[:file_name]
      end

      def handle_bad_http_response(code)
        case code
          when 401, 403
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
