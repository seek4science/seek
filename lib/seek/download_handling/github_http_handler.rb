# frozen_string_literal: true

require 'rest-client'
require_relative './http_handler'

module Seek
  module DownloadHandling
    class GithubHTTPHandler < Seek::DownloadHandling::HTTPHandler
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

        raw_url = "https://raw.githubusercontent.com/#{user}/#{repo}/#{branch}/#{path}"

        super(raw_url, fallback_to_get: fallback_to_get)
      end

      def info
        super.merge(@github_info)
      end
    end
  end
end
