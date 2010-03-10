# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'openssl'
module Jerm
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
  
  class HttpDownloader
    def get_remote_data url, username=nil, password=nil, type=nil
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
            return {:data=>f.read,:content_type=>f.content_type,:filename=>f.base_uri.path.split('/').last}
          else
            raise Exception.new("Problem fetching data from remote site - response code #{thing.status[0]}, url: #{url}")
          end
        end        
      rescue OpenURI::HTTPError => error
        raise Exception.new("Problem fetching data from remote site - response code #{error.io.status[0]}, url:#{url}")
      end
    end
    
  end
end