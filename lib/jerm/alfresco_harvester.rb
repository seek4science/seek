require 'jerm/web_dav_harvester'

class AlfrescoHarvester < WebDavHarvester
  
  def changed_since time
    items = super time
    return split_items(items).flatten
  end

  #required for where a directory contains multiple data items, with a single metadata
  def split_items items
    items.collect{|item| split_item(item)}
  end

  def split_item item
    metadata=item[:children].select{|c| c[:full_path].end_with?(meta_data_file)}.first
    if metadata.nil?
      puts "No metadata for: " + item[:full_path]
      return []
    end
    assets=item[:children].select{|c| c[:full_path].end_with?("xls")}
    res = assets.collect{|a| {:metadata=>metadata,:asset=>a}}
    return res
  end

end
