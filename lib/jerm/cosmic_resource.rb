require 'jerm/resource'
require 'jerm/alfresco_resource'

class CosmicResource < AlfrescoResource

    def initialize item
      super item
      @project="Cosmic"
    end
  
end
