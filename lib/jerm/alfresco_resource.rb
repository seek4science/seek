require 'web_dav_resource'
require 'fastercsv'

module Jerm
  class AlfrescoResource < WebDavResource

    attr_accessor :asset
    attr_accessor :metadata
    attr_accessor :author_seek_id
    attr_accessor :protocol   
  
    def initialize item,username,password
      super item
      @asset=item[:asset][:full_path]
      @metadata=item[:metadata][:full_path]
      @timestamp=item[:asset][:updated_at]
      @username=username
      @password=password
      @type=item[:type]
      @project=project_name
      @uri=@asset
    end    

    def populate
      read_metadata(@metadata)
    end

    def read_metadata metadata_uri
      #FIXME: will re-open the same metadata_uri multiple times here, which is inefficient. Should cache based upon the uri
      uri = URI.parse(metadata_uri)
      http=Net::HTTP.new(uri.host,uri.port)
      http.use_ssl=true if uri.scheme=="https"
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      req = Net::HTTP::Get.new(uri.path)
      req.basic_auth @username,@password unless @username.nil? or @password.nil?
      response = http.request(req)
      FasterCSV.parse(response.body) do |row|
        case row[0]
        when "ownerFirstName","ownerFirst"
          @author_first_name=row[1]
        when "ownerLastName","ownerLast"
          @author_last_name=row[1]
        when "ownerSeekId","ownerSeekID"
          @author_seek_id=row[1]
        when "cosmicProtocol"
          @protocol=row[1]
        end
      end
    end

  end
end