require 'jerm/web_dav_harvester'

module Jerm
  class AlfrescoHarvester < WebDavHarvester

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