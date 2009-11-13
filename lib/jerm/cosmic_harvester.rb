# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'jerm/alfresco_harvester'
require 'jerm/cosmic_resource'

module Jerm
  class CosmicHarvester < AlfrescoHarvester

    DIRECTORIES_AND_TYPES = {
      "models"=>{:ext=>["xml","xls"],:type=>"Model"},
      "protocols"=>{:ext=>["doc","pdf"],:type=>"SOP"},
      "transcriptomics"=>{:ext=>["xls"],:type=>"DataFile"},
      "metabolomics"=>{:ext=>["xls"],:type=>"DataFile"},
      "proteomics"=>{:ext=>["xls"],:type=>"DataFile"}
    }

    def construct_resource item
      CosmicResource.new(item,@username,@password)
    end

    def key_directories
      DIRECTORIES_AND_TYPES.keys      
    end

    def meta_data_file
      "metadata.csv"
    end

    def asset_extensions directory
      DIRECTORIES_AND_TYPES[directory][:ext]
    end
  
  end
end