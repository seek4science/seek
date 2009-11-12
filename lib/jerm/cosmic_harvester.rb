# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'jerm/alfresco_harvester'
require 'jerm/cosmic_resource'

module Jerm
  class CosmicHarvester < AlfrescoHarvester

    def construct_resource item
      CosmicResource.new(item,@username,@password)
    end

    def key_directories
      #["models","protocols","transcriptomics","metabolomics","proteomics"]
      ["transcriptomics"]
    end

    def meta_data_file
      "metadata.csv"
    end

    def data_file_extensions
      ["xls"]
    end

    def model_file_extensions
      ["xml"]
    end
  
  end
end