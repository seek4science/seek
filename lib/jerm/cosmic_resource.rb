require 'jerm/resource'
require 'jerm/alfresco_resource'

class CosmicResource < AlfrescoResource
    
  attr_accessor :asset 
  attr_accessor :metadata

  def initialize item,username,password
    super item,username,password
  end

  def populate
    read_metadata(@metadata)
    puts @metadata
    puts @asset
    puts @timestamp    
  end

  def read_metadata metadata_uri
    uri = URI.parse(metadata_uri)
    http=Net::HTTP.new(uri.host,uri.port)
    http.use_ssl=true if uri.scheme=="https"
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    req = Net::HTTP::Get.new(uri.path)
    req.basic_auth @username,@password
    response = http.request(req)
    puts response.body
  end
  
end
