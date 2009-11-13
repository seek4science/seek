require 'jerm/web_dav_harvester'

module Jerm
  class AlfrescoHarvester < WebDavHarvester

    def initialize username,password
      super username,password      
      @directories_and_types=@config['directories_and_types']
      @base_uri=@config['base_uri']
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