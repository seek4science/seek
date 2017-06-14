parent_xml.parameters do
  parent_xml.page params[:page]
end
@hidden ||= 0

parent_xml.statistics do
  parent_xml.total items.size + @hidden
  parent_xml.total_displayed items.size
  parent_xml.hidden @hidden
  if items.is_a?(Seek::GroupedPagination::Collection)
    pages = items.pages + ["latest","all"]
    parent_xml.pages pages.join(", ")
    parent_xml.page items.page  
    parent_xml.page_counts do
      items.page_totals.keys.sort.each do |key|
        parent_xml.page_count items.page_totals[key],{:page=>key}
      end
    end 
  end
end

parent_xml.items do
  items.each do |item|  
    api_partial parent_xml,item
  end      
end

parent_xml.related do
  if items.is_a?(Seek::GroupedPagination::Collection)
    pages = items.pages + ["latest","all"]
    pages.each do |page|
      parent_xml.tag! "page", {"xlink:href"=>assays_url(:page=>page)}
    end
  end
  
end
