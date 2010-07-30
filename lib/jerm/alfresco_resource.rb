require 'jerm/web_dav_resource'
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
      @filename=determine_filename(@asset)
    end    
    
    def populate      
      read_metadata(@metadata)      
    end
    
    def read_metadata metadata_uri
      #FIXME: will re-open the same metadata_uri multiple times here, which is inefficient. Should cache based upon the uri
      downloader = HttpDownloader.new
      data=downloader.get_remote_data(metadata_uri,@username,@password)[:data]
      FasterCSV.parse(data) do |row|
        case row[0]
          when "ownerFirstName","ownerFirst"
          @author_first_name=row[1]
          when "ownerLastName","ownerLast"
          @author_last_name=row[1]
          when "ownerSeekId","ownerSeekID"
          #@author_seek_id=row[1]
          @author_seek_id=1          
          when "cosmicProtocol"
          @protocol=row[1]
        end
      end
    end
    
    def determine_filename uri
      URI.unescape(uri).split("/").last
    end
    
  end
  
  
end