# frozen_string_literal: true

require 'rest-client'
require 'private_address_check'
require 'private_address_check/tcpsocket_ext'
require_relative './http_handler'

module Seek
  module DownloadHandling
    class GithubHTTPHandler < Seek::DownloadHandling::HTTPHandler
      include Seek::UploadHandling::ContentInspection

      def initialize(url, fallback_to_get: true)

        # The condition needs far more work
        if !url.end_with?('?raw=true')
          super(url + '?raw=true')
        else
          super(url)
        end
      end
    end
  end
end
