module Seek
  module DownloadHandling
    ##
    # A class to handle streaming remote content over FTP.
    class FTPStreamer

      def initialize(url)
        @url = url
      end

      # yields a chunk of data to the given block
      def stream(&block)
        total_size = 0
        uri = URI(@url)
        unless uri.userinfo.nil?
          username, password = uri.userinfo.split(/:/)
        end

        Net::FTP.open(uri.host) do |ftp|
          ftp.login(username || 'anonymous', password)
          ftp.getbinaryfile(uri.path) do |chunk|
            total_size += chunk.size
            raise SizeLimitExceededException.new(total_size) if total_size > max_size
            block.call(chunk)
          end
        end
      end

    end

    class SizeLimitExceededException < Exception; end
    class BadResponseCodeException < Exception; end
  end
end
