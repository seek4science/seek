# frozen_string_literal: true

require 'rest-client'
require 'private_address_check'
require 'private_address_check/tcpsocket_ext'

module Seek
  module DownloadHandling
    class HTTPHandler
      include Seek::UploadHandling::ContentInspection

      attr_reader :url

      def initialize(url, fallback_to_get: true)
        @url = url
        @fallback_to_get = fallback_to_get
      end

      def info
        content_type = nil
        content_length = nil
        file_name = nil
        code = nil
        p = proc do
          begin
            response = RestClient.head(url, accept: '*/*')
            content_type = if is_slideshare_url?
                             'text/html'
                           else
                             response.headers[:content_type]
                           end
            content_length = response.headers[:content_length]
            file_name = determine_filename_from_disposition(response.headers[:content_disposition])
            code = response.code
          rescue RestClient::UnsupportedMediaType => e
            accept_header = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
            response = RestClient.head(url, accept: accept_header)
            content_type = response.headers[:content_tyspe]
            content_length = response.headers[:content_length]
            code = response.code
          rescue RestClient::MethodNotAllowed,RestClient::NotFound => e # Try a GET if HEAD isn't allowed, but don't download anything
            if @fallback_to_get
              begin
                uri = URI.parse(url)
                Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
                  http.request(Net::HTTP::Get.new(uri)) do |res|
                    content_type = res['content-type']
                    content_length = res['content-length']
                    file_name = determine_filename_from_disposition(res['content-disposition'])
                    code = res.code.try(:to_i)
                  end
                end
              rescue Seek::DownloadHandling::BadResponseCodeException => e2
                code = e2.code
              end
            else
              code = e.http_code
            end
          rescue RestClient::Exception => e
            code = e.http_code
          rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH
            code = 404
          end
        end

        begin
          if Seek::Config.allow_private_address_access
            p.call
          else
            PrivateAddressCheck.only_public_connections { p.call }
          end
        rescue PrivateAddressCheck::PrivateConnectionAttemptedError
          code = 490 # A made up error code to be handled internally by SEEK
        end

        file_name ||= determine_filename_from_url(@url)
        content_type ||= content_type_from_filename(file_name)

        {
          code: code,
          file_size: content_length.present? ? content_length.try(:to_i) : nil,
          content_type: content_type,
          file_name: file_name
        }
      end

      def fetch
        file = Tempfile.new('remote-content')
        file.binmode # Strange encoding issues occur if this is not set

        Seek::DownloadHandling::HTTPStreamer.new(url, size_limit: Seek::Config.hard_max_cachable_size).stream do |chunk|
          file << chunk
        end

        file
      end

      private

      # if it is a slideshare url, which starts with www.slideshare.net, and is made up of 2 parts (params ignored)
      # i.e http://www.slideshare.new/<org>/<slidetitle>
      #
      # this is a quick fix to get around slideshare not always giving a content type of text/html, and instead sometimes giving application/xml
      def is_slideshare_url?
        renderer = Seek::Renderers::SlideshareRenderer.new(nil)
        renderer.is_slideshare_url?(url)
      end
    end
  end
end
