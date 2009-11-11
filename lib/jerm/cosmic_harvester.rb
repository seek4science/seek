# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'jerm/alfresco_harvester'
require 'jerm/cosmic_resource'

class CosmicHarvester < AlfrescoHarvester

  def construct_resource item
    CosmicResource.new(item)    
  end

  def key_directories
    ["models","protocols","transcriptomics","metabolomics","proteomics"]
  end


end
