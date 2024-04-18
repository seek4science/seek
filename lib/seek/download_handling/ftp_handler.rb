require 'net/ftp'

module Seek
  module DownloadHandling
    class FTPHandler
      include Seek::UploadHandling::ContentInspection

      def initialize(url)
        @url = url
      end

      def info
        uri = URI(@url)
        username, password = uri.userinfo.split(/:/) unless uri.userinfo.nil?

        size = nil
        Net::FTP.open(uri.host) do |ftp|
          ftp.login(username || 'anonymous', password)
          size = ftp.size(uri.path)
        end

        file_name = determine_filename_from_url(@url)
        content_type = content_type_from_filename(file_name)

        {
          file_size: size,
          content_type: content_type,
          file_name: file_name
        }
      end

      def fetch
        file = Tempfile.new('remote-content')
        file.binmode # Strange encoding issues occur if this is not set

        Seek::DownloadHandling::FTPStreamer.new(@url, size_limit: Seek::Config.hard_max_cachable_size).stream do |chunk|
          file << chunk
        end

        file
      end
    end
  end
end
