module Seek
  module UploadHandling
    module ContentInspection
      include Seek::MimeTypes

      INVALID_SCHEMES = %w(file)

      def valid_scheme?(url)
        uri = URI.encode((url || '').strip)
        scheme = URI.parse(uri).scheme
        !INVALID_SCHEMES.include?(scheme)
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
        return nil unless content_type
        # remove charset, e.g. "text/html; charset=UTF-8"
        raw_type = content_type.split(';')[0] || ''
        raw_type.strip.downcase
      end

      def fetch_url_headers(url)
        RestClient.head(url, accept: :html).headers
      end

      def summarize_webpage(url)
        MetaInspector.new(url, allow_redirections: true)
      end

      def content_type_from_filename(filename)
        if !filename
          'text/html' # assume it points to a webpage if there is no filename
        else
          file_format = filename.split('.').last.try(:strip)
          possible_mime_types = mime_types_for_extension file_format
          type = possible_mime_types.sort.first || 'application/octet-stream'
          type
        end
      end

      def valid_uri?(uri)
        uri.try(:strip) =~ /\A#{URI.regexp}\z/
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
    end
  end
end
