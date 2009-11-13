require 'jerm/web_dav_harvester'

module Jerm
  class AlfrescoHarvester < WebDavHarvester
  
    def changed_since time
      super time      
    end

    #required for where a directory contains multiple data items, with a single metadata
    def split_items items,extensions
      items.collect{|item| split_item(item,extensions)}
    end

    def split_item item,extensions
      metadata=item[:children].select{|c| c[:full_path].end_with?(meta_data_file)}.first
      if metadata.nil?
        puts "No metadata for: " + item[:full_path]
        return []
      end
      assets=item[:children].select{|c| !extensions.detect{|ext| c[:full_path].end_with?(ext)}.nil?}
      res = assets.collect{|a| {:metadata=>metadata,:asset=>a}}
      return res
    end

  end
end