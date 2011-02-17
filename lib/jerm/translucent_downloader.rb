module Jerm
  class TranslucentDownloader

    class TranslucentDownloadException < JermException

    end

    def get_remote_data url, username=nil, password=nil, type=nil, include_data=true
      raise TranslucentDownloadException.new "Downloading remote Translucent data is currently unavailable.<br/> This will be fixed when SEEK is re-integrated with the new Translucent pyMantis system."
    end

  end
end