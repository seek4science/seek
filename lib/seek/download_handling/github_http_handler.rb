# frozen_string_literal: true

require 'rest-client'
require 'private_address_check'
require 'private_address_check/tcpsocket_ext'
require_relative './http_handler'

module Seek
  module DownloadHandling
    class GithubHttpHandler < Seek::DownloadHandling::HttpHandler
      attr_reader :github_info

      def initialize(url, fallback_to_get: true)
        uri = URI(url)
        if uri.hostname.include?('github.com')
          user, repo, format, branch, path = uri.path.split('/', 6)[1..-1]
        else
          user, repo, branch, path = uri.path.split('/', 5)[1..-1]
        end

        @github_info = { github_user: user,
                         github_repo: repo,
                         github_branch: branch,
                         github_path: path }

        super(raw_url, fallback_to_get: fallback_to_get)
      end

      def info
        super.merge(@github_info)
      end

      def raw_url
        "https://raw.githubusercontent.com/#{@github_info[:github_user]}/#{@github_info[:github_repo]}/#{@github_info[:github_branch]}/#{@github_info[:github_path]}"
      end

      def repository_url
        "https://github.com/#{@github_info[:github_user]}/#{@github_info[:github_repo]}"
      end
    end
  end
end
