require 'jerm/resource'
require 'jerm/alfresco_resource'

class CosmicResource < AlfrescoResource
    
  attr_accessor :asset 
  attr_accessor :metadata

  def initialize item,username,password
    super item,username,password
  end

  def populate
    puts @metadata
    puts @asset
    puts @timestamp    
  end
  
end
