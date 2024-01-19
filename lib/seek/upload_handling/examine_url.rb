module Seek
  module UploadHandling
    module ExamineUrl
      include Seek::UploadHandling::ContentInspection

      def examine_url
        # check content type and size
        url = params[:data_url]
        @info = {}
        @type = 'file'
        @content_blob = ContentBlob.new(url: url)
        begin
          uri = URI(url)
          handler = @content_blob.remote_content_handler
          if handler
            @info = handler.info
            if @info[:code]
              if @info[:code] == 200
                handle_good_http_response(handler)
              else
                handle_bad_http_response(@info[:code])
              end
            end
          else
            @type = 'warning'
            @warning_msg = "Unhandled URL scheme: #{uri.scheme}. The given URL will be presented as a clickable link."
          end
        rescue StandardError => e
          handle_exception_response(e)
        end

        respond_to do |format|
          format.html { render partial: 'content_blobs/examine_url_result', status: ( @type == 'error'|| @type == 'override') ? 400 : 200 }
        end
      end

      private

      def handle_good_http_response(handler)
        if handler.is_a?(Seek::DownloadHandling::GithubHTTPHandler)
          @type = 'github'
        elsif handler.is_a?(Seek::DownloadHandling::GalaxyHTTPHandler)
          @type = 'galaxy'
        elsif is_myexperiment_url?(handler.url)
          @type = 'webpage'
          xml_url = url[0..-6] + '.xml'

          xml_doc = Nokogiri::XML(open(xml_url))
          xml_doc.xpath('/*/description').each do |node|
            @info[:description] = node.text
          end
          xml_doc.xpath('/*/title').each do |node|
            @info[:title] = node.text
          end
          xml_doc.xpath('/*/preview').each do |node|
            @info[:image] = node.text
          end
        elsif content_is_webpage?(@info[:content_type])
          @type = 'webpage'
          page = summarize_webpage(handler.url)
          @info[:title] = page.title&.strip
          @info[:description] = page.description&.strip
          @info[:image] = page.images.best
        end
      end

      def handle_bad_http_response(code)
        @type = 'error'

        case code
        when 401, 403
          @type = 'warning'
          @warning_msg = "Access to this link is unauthorized. You can still register it as a link, but somebody wishing to access it may need a username and password to login to the site and download the file."
        when 405
          @error_msg = "We can't find out information about this URL - Method not allowed response."
        when 404
          @type = 'override'
          @error_msg = 'Nothing can be found at that URL. Please check the address and try again'
        when 400
          @type = 'override'
          @error_msg = 'The URL appears to be invalid'
        when 490
          @error_msg = 'That URL is inaccessible. Please check the address and try again'
        else
          @error_msg = "We can't find out information about this URL - unhandled response code: #{code}"
        end
      end

      def handle_exception_response(exception)
        case exception
        when URI::InvalidURIError
          handle_bad_http_response(400)
        else
          fail exception
        end
      end

      def is_myexperiment_url?(url)
        URI uri = URI(url)
        uri.hostname.include?('myexperiment.org') && uri.path.end_with?('.html')
      end
    end
  end
end
