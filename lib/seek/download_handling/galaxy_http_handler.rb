# frozen_string_literal: true

require 'rest-client'
require 'private_address_check'
require 'private_address_check/tcpsocket_ext'
require_relative './http_handler'

module Seek
  module DownloadHandling
    class GalaxyHTTPHandler < Seek::DownloadHandling::HTTPHandler
      attr_reader :galaxy_host, :workflow_id

      URL_PATTERNS = [
        /(.+)\/api\/workflows\/([^\/]+)\/download\?format=json-download/, # Download
        /(.+)\/workflows\/run\?id=([^&]+)/, # Run
        /(.+)\/published\/workflow\?id=([^&]+)/, # View
      ].freeze

      def initialize(url, fallback_to_get: true)
        URL_PATTERNS.each do |pattern|
          matches = url.match(pattern)
          if matches
            @galaxy_host = matches[1].chomp('/') + '/'
            @workflow_id = matches[2]
          end
        end

        super(download_url, fallback_to_get: fallback_to_get)
      end

      def info
        super.merge(galaxy_host: galaxy_host,
                    workflow_id: workflow_id,
                    display_url: display_url)
      end

      def display_url
        URI.join(galaxy_host, "published/workflow?id=#{workflow_id}").to_s
      end

      def download_url
        URI.join(galaxy_host, "api/workflows/#{workflow_id}/download?format=json-download").to_s
      end

      def run_url
        URI.join(galaxy_host, "workflows/run?id=#{workflow_id}").to_s
      end

      def execution_instance_url
        galaxy_host.to_s
      end

      def self.is_galaxy_workflow_url?(uri)
        string_uri = uri.to_s
        uri.hostname.include?('galaxy') && URL_PATTERNS.any? { |pattern| string_uri.match?(pattern) }
      end
    end
  end
end
