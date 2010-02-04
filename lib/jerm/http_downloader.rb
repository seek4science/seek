# To change this template, choose Tools | Templates
# and open the template in the editor.
module Jerm
  class HttpDownloader < ResourceDownloader
    def get_remote_data url
      return basic_auth url
    end

    private

    #handles fetching data using basic authentication. Handles http and https.
    def basic_auth url
      uri = URI.parse(url)
      http=Net::HTTP.new(uri.host,uri.port)
      http.use_ssl=true if uri.scheme=="https"
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      req = Net::HTTP::Get.new(uri.path)
      req.basic_auth @username,@password unless @username.nil? or @password.nil?
      response = http.request(req)
      if response.code == "200"
        #FIXME: need to handle full range of 2xx sucess responses, in particular where the response is only partial
        return {:data=>response.body}
      else
        raise Exception.new("Problem fetching data from remote site - response code #{response.code}")
      end
    end
    
  end
end