module Seek
  module UploadHandling
    module ExamineUrl
      include Seek::UploadHandling::ContentInspection

      def examine_url
        # check content type and size
        url = params[:data_url]
        @info = {}
        @type = 'file'
        begin
          uri = URI(url)
          case scheme = uri.scheme
          when 'ftp'
            handler = Seek::DownloadHandling::FTPHandler.new(url)
            @info = handler.info
          when 'http', 'https', nil
            handler = Seek::DownloadHandling::HTTPHandler.new(url)
            @info = handler.info
            if @info[:code] == 200
              handle_good_http_response(handler)
            else
              handle_bad_http_response(@info[:code])
            end
          else
            @type = 'warning'
            @warning_msg = "Unhandled URL scheme: #{scheme}. The given URL will be presented as a clickable link."
          end
        rescue StandardError => e
          handle_exception_response(e)
        end

        respond_to do |format|
          format.html { render partial: 'content_blobs/examine_url_result', status: @type == 'error' ? 400 : 200 }
        end
      end

      private

      def handle_good_http_response(handler)
        if is_github_url?(handler.url)
          @type = 'github'
          uri = URI(handler.url)
          if uri.hostname.include?('github.com')
            user, repo, format, branch, path = uri.path.split('/', 6)[1..-1]
          else
            user, repo, branch, path = uri.path.split('/', 5)[1..-1]
          end
          @info[:github_user] = user
          @info[:github_repo] = repo
          @info[:github_branch] = branch
          @info[:github_path] = path
          raw_url = "https://raw.githubusercontent.com/#{user}/#{repo}/#{branch}/#{path}"
          raw_handler = Seek::DownloadHandling::HTTPHandler.new(raw_url)
          @info.merge!(raw_handler.info)
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
          @info[:title] = page.title
          @info[:description] = page.description
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
          @error_msg = 'Nothing can be found at that URL. Please check the address and try again'
        when 400
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

      def handle_myexperiment_response
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
      end

      def is_myexperiment_url?(url)
        URI uri = URI(url)
        uri.hostname.include?('myexperiment.org') && uri.path.end_with?('.html')
      end

      def is_github_url?(url)
        URI uri = URI(url)
        uri.hostname.include?('github.com') || uri.hostname.include?('raw.githubusercontent.com')
      end
    end
  end
end
