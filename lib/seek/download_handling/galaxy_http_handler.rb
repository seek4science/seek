# frozen_string_literal: true

require 'rest-client'
require 'private_address_check'
require 'private_address_check/tcpsocket_ext'
require_relative './http_handler'

module Seek
  module DownloadHandling
    class GalaxyHTTPHandler < Seek::DownloadHandling::HTTPHandler
      attr_reader :galaxy_host, :workflow_id

      def initialize(url, fallback_to_get: true)
        uri = URI(url)

        @galaxy_host = URI(url.split(/\/workflows?\//).first + '/')
        @workflow_id = CGI.parse(uri.query)['id'].first

        super(download_url, fallback_to_get: fallback_to_get)
      end

      def info
        super.merge(galaxy_host: galaxy_host,
                    workflow_id: workflow_id,
                    display_url: display_url)
      end

      def display_url
        URI.join(galaxy_host, "workflow/display_by_id?id=#{workflow_id}").to_s
      end

      def download_url
        URI.join(galaxy_host, "workflow/export_to_file?id=#{workflow_id}").to_s
      end

      # Note that the path is `/workflows/` (plural) here for some reason.
      def run_url
        URI.join(galaxy_host, "workflows/run?id=#{workflow_id}").to_s
      end

      def self.is_galaxy_workflow_url?(uri)
        uri.hostname.include?('galaxy') && (uri.path.include?('/workflow/') || uri.path.include?('/workflows/')) &&
          uri.query.present? && CGI.parse(uri.query)&.key?('id')
      end
    end
  end
end
