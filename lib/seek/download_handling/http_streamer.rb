# frozen_string_literal: true

require 'private_address_check'
require 'private_address_check/tcpsocket_ext'

module Seek
  module DownloadHandling
    ##
    # A class to handle streaming remote content over HTTP.
    # Monitors the number of bytes downloading and terminates
    #  if it exceeds a given limit.
    class HTTPStreamer
      REDIRECT_LIMIT = 10

      def initialize(url, options = {})
        @url = url
        @size_limit = options[:size_limit]
      end

      # yields a chunk of data to the given block
      def stream(&block)
        get_uri(URI(@url), 0, block)
      end

      private

      def get_uri(uri, redirect_count, block)
        p = proc do
          Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
            http.request(Net::HTTP::Get.new(uri)) do |response|
              if response.code == '200'
                begin_stream(response, block)
              elsif response.code == '301' || response.code == '302'
                follow_redirect(uri, response, redirect_count, block)
              else
                raise BadResponseCodeException.new(code: response.code), response.message
              end
            end
          end
        end

        if Seek::Config.allow_private_address_access
          p.call
        else
          PrivateAddressCheck.only_public_connections { p.call }
        end
      end

      def begin_stream(response, block)
        total_size = 0

        response.read_body do |chunk|
          total_size += chunk.size
          raise SizeLimitExceededException, total_size if @size_limit && (total_size > @size_limit)
          block.call(chunk)
        end

        total_size
      end

      def follow_redirect(uri, response, redirect_count, block)
        if redirect_count >= REDIRECT_LIMIT
          raise RedirectLimitExceededException, redirect_count
        else
          new_uri = URI(response.header['location'])
          new_uri = URI(uri) + new_uri if new_uri.relative?

          get_uri(new_uri, redirect_count + 1, block)
        end
      end
    end

    class RedirectLimitExceededException < RuntimeError; end
    class SizeLimitExceededException < RuntimeError; end
    class BadResponseCodeException < RuntimeError
      attr_reader :code

      def initialize(message = nil, code: nil)
        super(message)
        @code = code
      end
    end
  end
end
