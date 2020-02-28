module Seek
  module UploadHandling
    module ExamineUrl
      include Seek::UploadHandling::ContentInspection

      def handle_good_http_response(url, info)
        @content_type = info[:content_type]
        @size = info[:file_size]
        if content_is_webpage?(@content_type)
          @is_webpage = true
          if is_myexperiment_url? url
          else
            page = summarize_webpage(url)
            @title = page.title&.strip
            @description = page.description&.strip
            @image = page.images.best
          end
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
        when 490
          @error = true
          @error_msg = 'That URL is inaccessible. Please check the address and try again'
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
          raise exception
        end
      end

      def is_myexperiment_url?(url)
        URI uri = URI(url)
        @is_workflow = false
        return false unless uri.hostname.include? 'myexperiment'
        return false unless uri.path.end_with? '.html'
        @is_workflow = true if uri.path.include? '/workflow'
        begin
          xml_url = url[0..-6] + '.xml'

          xml_doc = Nokogiri::XML(open(xml_url))
          xml_doc.xpath('/*/description').each do |node|
            @description = node.text
          end
          xml_doc.xpath('/*/title').each do |node|
            @title = node.text
          end
          xml_doc.xpath('/*/preview').each do |node|
            @image = node.text
          end
          return true
        rescue
          return false
        end
        false
      end

    end
  end
end
