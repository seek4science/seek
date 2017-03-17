require 'openssl'
require 'fileutils'
require 'net/ftp'

module Seek
  # Handles downloading data files from a Remote site, together with authentication using the provided username and password.
  # Includes some simple file caching to prevent multiple downloads of the same item
  class RemoteDownloader
    @@file_cache = {}
    @@filename_cache = {}

    def get_remote_data(url, username = nil, password = nil, _type = nil, include_data = true)
      cached = check_from_cache(url, username, password)
      return cached unless cached.nil?
      uri = parse_and_encode_url(url)
      if %w(http https).include? uri.scheme
        return basic_auth url, username, password, include_data
      elsif uri.scheme == 'ftp'
        return fetch_from_ftp url, username, password, include_data
      else
        fail URI::InvalidURIError.new('Only http, https and ftp are supported')
      end
    end

    # tries to determine the filename from f
    # if it can it will read the content-disposition and parse the filename, otherwise falls back to what follows the last / in the uri
    def determine_filename(f)
      return @@filename_cache[f.base_uri] unless @@filename_cache[f.base_uri].nil?
      disp = f.meta['content-disposition']
      result = nil
      unless disp.nil?
        m = /filename=\".*\"/.match(disp)
        if m
          m = /\".*\"/.match(m[0])
          result = m[0].delete("\"").split('/').last if m
        end
      end
      result = f.base_uri.path.split('/').last if result.nil?
      @@filename_cache[f.base_uri] = result
      result
    end

    private

    # handles fetching data using basic authentication. Handles http and https.
    # returns a hash that contains the following:
    # :data_tmp_path=> a path to a temporary copy of the data
    # :content_type=> the content_type
    # :filename => the filename
    #
    # throws an Exception if anything goes wrong.
    def basic_auth(url, username, password, _include_data = true)
      # This block is to ensure that only urls are encoded if they need it.
      # This is to prevent already encoded urls being re-encoded, which can lead to % being replaced with %25.
      begin
        URI.parse(url)
      rescue URI::InvalidURIError
        url = URI.encode(url)
      end

      begin
        auth_params = {}
        auth_params[:http_basic_authentication] = [username, password] unless username.nil? && password.nil?

        open(url, auth_params) do |f|
          # FIXME: need to handle full range of 2xx success responses, in particular where the response is only partial
          if f.status[0] == '200'
            result = { content_type: f.content_type, filename: determine_filename(f) }
            result = cache f, result, url, username, password
            return result
          else
            fail DownloadException.new("Problem fetching data from remote site - response code #{thing.status[0]}, url: #{url}")
          end
        end
      rescue OpenURI::HTTPError => error
        raise DownloadException.new("Problem fetching data from remote site - response code #{error.io.status[0]}, url:#{url}")
      end
    end

    # fetches from an FTP based url. If the url contains username and password information then this is used instead of
    # that passed in. If no username and password is provided, then anonymous is assumed
    def fetch_from_ftp(url, username = nil, password = nil, _include_data = true)
      uri = URI.parse(url)
      username, password = uri.userinfo.split(/:/) unless uri.userinfo.nil?

      username = 'anonymous' if username.nil?

      ftp = Net::FTP.new(uri.host)
      ftp.login(username, password)
      tmp = Tempfile.new('_seek')
      ftp.getbinaryfile(uri.path, tmp.path)
      ftp.close
      result = { filename: File.basename(url), content_type: nil }
      result = cache tmp, result, url, username, password
      result
    end

    # returns a hash that contains
    # :data
    # :content_type
    # :filename
    # :time_stored
    # :uuid
    # if present in the cache.
    # returns nil if either it is not available in the cache, or the time_stored is older than 1hr ago
    def check_from_cache(url, username, password)
      key = generate_key url, username, password

      res = @@file_cache[key]

      return nil if res.nil? || !File.exist?(res[:data_tmp_path])

      if (res[:time_stored] + 3600) < Time.now
        FileUtils.rm res[:data_tmp_path]
        return nil
      end

      res
    end

    # caches the result into a temporary file
    def cache(file_obj, data_result, url, username, password)
      data_result[:uuid] = UUID.generate
      key = generate_key url, username, password

      begin
        data_result[:data_tmp_path] = store_data_to_tmp file_obj, data_result[:uuid]
        data_result[:time_stored] = Time.now
        @@file_cache[key] = data_result
      rescue Exception => e
        @@file_cache[key] = nil
      end
    end

    def store_data_to_tmp(file_obj, uuid)
      path = cached_path(uuid)
      file_obj.rewind
      File.open(path, 'wb') do |f|
        buffer = ''
        f << buffer while file_obj.read(16_384, buffer)
      end

      path
    end

    def cached_path(uuid)
      path = "#{Rails.root}/tmp/cache/downloader_cache/"
      FileUtils.mkdir_p(path)
      "#{path}/#{uuid}.dat"
    end

    def generate_key(url, username, password)
      "#{url}+#{username}+#{password}"
    end

    def parse_and_encode_url(url)
      return URI.parse(url)
    rescue URI::InvalidURIError
      url = URI.encode(url)
      return URI.parse(url)
    end
  end
end
