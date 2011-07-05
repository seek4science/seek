require 'test_helper'

class RemoteDownloaderTest < ActiveSupport::TestCase  

  def setup
    stub_request :get,"mockedlocation.com/a-file.txt"
    @downloader = Seek::RemoteDownloader.new
  end

  def test_caching
    res = @downloader.get_remote_data("http://mockedlocation.com/a-file.txt","","")
    assert_not_nil res[:data_tmp_path]

    #need to add this to access the private check_from_cache method
    class << @downloader
      def cached_element url,uname,password
        return check_from_cache url,uname,password
      end
    end

    cached=@downloader.cached_element("http://mockedlocation.com/a-file.txt","","")
    assert_not_nil cached
    assert_equal res[:data_tmp_path],cached[:data_tmp_path]
    assert_not_nil cached[:time_stored]
    assert_not_nil cached[:uuid]

    res2 = @downloader.get_remote_data("http://mockedlocation.com/a-file.txt","","")
    assert_equal res[:data_tmp_path],res2[:data_tmp_path]
    assert_equal res[:filename],res2[:filename]
    assert_equal res[:content_type],res2[:content_type]
  end

  def test_fetch_from_http
    http_url = "http://mockedlocation.com/a-file.txt"

    res = @downloader.get_remote_data(http_url)
    assert_not_nil res[:data_tmp_path]
    assert File.exists?(res[:data_tmp_path])
    assert_equal "a-file.txt",res[:filename]
  end

  def test_fetch_from_ftp
    puts "Skipping RemoteDownloaderTest#test_fetch_from_ftp"
    return
    ftp_url = "ftp://ftp.mirrorservice.org/sites/amd64.debian.net/robots.txt"
    
    res = @downloader.get_remote_data(ftp_url)
    assert_not_nil res[:data_tmp_path]
    assert File.exists?(res[:data_tmp_path])
    assert_equal "robots.txt",res[:filename]
  end

end
