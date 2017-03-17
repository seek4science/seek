require 'net/ftp'

module Seek
  module DownloadHandling
    ##
    # A class to handle streaming remote content over FTP.
    class FTPStreamer
      def initialize(url, options = {})
        @url = url
        @size_limit = options[:size_limit]
      end

      # yields a chunk of data to the given block
      def stream(&block)
        total_size = 0

        uri = URI(@url)
        username, password = uri.userinfo.split(/:/) unless uri.userinfo.nil?

        Net::FTP.open(uri.host) do |ftp|
          ftp.login(username || 'anonymous', password)
          # Setting the flag below prevented:
          #  app error: "500 Illegal PORT command.\n" (Net::FTPPermError)
          ftp.passive = true
          ftp.getbinaryfile(uri.path) do |chunk|
            total_size += chunk.size
            fail SizeLimitExceededException.new(total_size) if @size_limit && (total_size > @size_limit)
            block.call(chunk)
          end
        end
      end
    end

    class SizeLimitExceededException < Exception; end
  end
end
