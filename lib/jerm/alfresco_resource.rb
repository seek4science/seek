require 'jerm/web_dav_resource'

module Jerm
  class AlfrescoResource < WebDavResource
  
    def initialize item,username,password
      super item
      @asset=item[:asset][:full_path]
      @metadata=item[:metadata][:full_path]
      @timestamp=item[:asset][:updated_at]
      @username=username
      @password=password
      @type=item[:type]
    end

  end
end