# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'openssl'
require 'uuidtools'

module Jerm
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE  
  
  class HttpDownloader
    @@file_cache={}
    
    def get_remote_data url, username=nil, password=nil, type=nil
      cached=check_from_cache(url,username,password)
      return cached unless cached.nil?
      return basic_auth url, username, password
    end

    private

    #handles fetching data using basic authentication. Handles http and https.
    #returns a hash that contains the following:
    # :data=> the data
    # :content_type=> the content_type
    # :filename => the filename
    #
    # throws an Exception if anything goes wrong.
    def basic_auth url, username,password

      #This block is to ensure that only urls are encoded if they need it.
      #This is to prevent already encoded urls being re-encoded, which can lead to % being replaced with %25.
      begin
        URI.parse(url)
      rescue URI::InvalidURIError
        url=URI.encode(url)
      end
      
      begin
        open(url,:http_basic_authentication=>[username, password]) do |f|
          #FIXME: need to handle full range of 2xx sucess responses, in particular where the response is only partial
          if f.status[0] == "200"                    
            result = {:data=>f.read,:content_type=>f.content_type,:filename=>f.base_uri.path.split('/').last}
            cache result,url,username,password
            return result
          else
            raise Exception.new("Problem fetching data from remote site - response code #{thing.status[0]}, url: #{url}")
          end
        end        
      rescue OpenURI::HTTPError => error
        raise Exception.new("Problem fetching data from remote site - response code #{error.io.status[0]}, url:#{url}")
      end
      
    end

    #returns a hash that contains
    # :data
    # :content_type
    # :filename
    # :time_stored
    # :uuid
    # if present in the cache.
    # returns nil if either it is not available in the cache, or the time_stored is older than 1hr ago
    def check_from_cache url,username,password
      key=generate_key url,username,password
      res=@@file_cache[key]

      return nil if res.nil?
      return nil if (res[:time_stored] + 3600) < Time.now
      
      res[:data]=read_data_from_tmp res[:uuid]
      return res
    end

    def read_data_from_tmp uuid
      data=nil
      File.open(cached_path(uuid), 'r') do |f|
        data=f.read
      end
      return data
    end
    
    #caches the result into a temporary file
    def cache data_result,url,username,password
      data_result[:uuid]=UUIDTools::UUID.random_create.to_s
      key=generate_key url,username,password
      cached={}
      data_result.keys.each{|k| cached[k]=data_result[k] unless k==:data}
      begin
        store_data_to_tmp data_result[:data],data_result[:uuid]
        cached[:time_stored]=Time.now
        @@file_cache[key]=cached
      rescue
        @@file_cache[key]=nil
      end      
    end

    def store_data_to_tmp data,uuid
      File.open(cached_path(uuid), 'w') do |f|
        f.write data
      end
    end

    def cached_path uuid
      path = "#{RAILS_ROOT}/tmp/cache/downloader_cache/"
      FileUtils.mkdir_p(path)
      return "#{path}/#{uuid}.dat"
    end

    def generate_key url,username,password
      "#{url}+#{username}+#{password}"
    end

  end
end