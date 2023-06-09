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
        @redirect_limit = options[:redirect_limit] || REDIRECT_LIMIT
      end

      # yields a chunk of data to the given block
      def stream(&block)
        get_uri(URI(@url), &block)
      end

      # Does a GET (following redirects according to @redirect_limit) without downloading any of the response body.
      def peek
        get_uri(URI(@url))
      end

      private

      def get_uri(uri, redirect_count = 0, &block)
        p = proc do
          Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
            http.request(Net::HTTP::Get.new(uri)) do |response|
              if response.code == '200'
                if block_given?
                  begin_stream(response, &block)
                else
                  return response
                end
              elsif response.code == '301' || response.code == '302'
                follow_redirect(uri, response, redirect_count, &block)
              else
                raise BadResponseCodeException.new(code: response.code.to_i), response.message
              end
            end
          end
        end

        if Seek::Config.allow_private_address_access
          p.call
        else
          PrivateAddressCheck.only_public_connections { p.call }
        end

        nil
      end

      def begin_stream(response, &block)
        total_size = 0

        response.read_body do |chunk|
          total_size += chunk.size
          raise SizeLimitExceededException, total_size if @size_limit && (total_size > @size_limit)
          block.call(chunk)
        end

        total_size
      end

      def follow_redirect(uri, response, redirect_count, &block)
        if redirect_count >= @redirect_limit
          raise RedirectLimitExceededException, redirect_count
        else
          new_uri = URI(response.header['location'])
          new_uri = URI(uri) + new_uri if new_uri.relative?

          get_uri(new_uri, redirect_count + 1, &block)
        end
      end
    end
  end
end
