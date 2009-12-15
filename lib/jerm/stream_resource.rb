# To change this template, choose Tools | Templates
# and open the template in the editor.

module Jerm
  class StreamResource < Resource

    attr_accessor :username, :password
    
    def populate
      
    end
    
    def get_data
      uri = URI.parse(uri)
      http=Net::HTTP.new(uri.host,uri.port)
      http.use_ssl=true if uri.scheme=="https"
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      req = Net::HTTP::Get.new(uri.request_uri)
      req.basic_auth username, password unless username.nil? or password.nil?
      response = http.request(req)
      return response.body
    end
              
  end
end
