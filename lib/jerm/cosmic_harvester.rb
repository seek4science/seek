# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'jerm/alfresco_harvester'
require 'jerm/cosmic_resource'
require 'yaml'

module Jerm
  class CosmicHarvester < AlfrescoHarvester

    def initialize username,password      
      super username,password
      configpath=File.join(File.dirname(__FILE__),'config/cosmic.yml')      
      config=YAML::load_file(configpath)
      @directories_and_types=config['directories_and_types']
      @base_uri=config['base_uri']
    end

    def construct_resource item
      CosmicResource.new(item,@username,@password)
    end

    def key_directories
      @directories_and_types.keys
    end

    def meta_data_file
      "metadata.csv"
    end

    def asset_extensions directory
      @directories_and_types[directory]['ext']
    end

    def asset_type directory
      @directories_and_types[directory]['type']
    end
  
  end
end