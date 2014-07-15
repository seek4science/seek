module Seek
  module UploadHandling
    VALID_SCHEMES = %w(http https ftp)
    def valid_scheme?(url)
      uri = URI.encode((url || '').strip)
      scheme = URI.parse(uri).scheme
      VALID_SCHEMES.include?(scheme)
    end

    def check_url_response_code(url)
      RestClient.head(url).code
    rescue RestClient::ResourceNotFound
      404
    rescue RestClient::InternalServerError
      500
    rescue RestClient::Forbidden
      403
    end

    def content_is_webpage?(content_type)
      content_type||=""
      # remove charset, e.g. "text/html; charset=UTF-8"
      raw_type = content_type.split(";")[0] || "";
      raw_type = raw_type.strip.downcase
      return raw_type=="text/html"
    end

    def fetch_url_headers(url)
      RestClient.head(url).headers
    end

    def summarize_webpage(url)
      MetaInspector.new(url,:allow_redirections=>true)
    end

    def process_view_for_successful_url(url)
      headers = fetch_url_headers(url)
      @content_type = headers[:content_type]
      @size = headers[:content_length]
      @size_mb = @size.to_i / 10000
      if content_is_webpage?(@content_type)

        @is_webpage=true
        page = summarize_webpage(url)
        @title = page.title
        @description = page.description
        @image = page.image
        @image ||= page.images[0] unless page.images.blank?
      else
        @is_webpage=false
      end
    end
  end

  module Exceptions
    class InvalidSchemeException < Exception; end
  end
end
