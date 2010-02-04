# To change this template, choose Tools | Templates
# and open the template in the editor.
module Jerm

  #Root class for all the project specific downloaders
  #Sub classes should implement the method get_remote_data
  #which makes use of the methods in the base class to return a hash that contains:
  #
  # :data=> the data for the item that was requested to be downloaded (Required)
  # :filename=> the filename of the item to be downloaded (Optional)
  # :content_type=> the content type for the item to be downloaded (Optional)
  class ResourceDownloader

    #initialises the downloader with the required username and password which may be omitted if authentication is not required.
    def initialize username=nil,password=nil
      @username=username
      @password=password
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
      return {:data=>response.body}
    end
    
  end

end