parent_xml.parameters do
  api_index_parameters parent_xml,params
end

parent_xml.statistics do
  
end

parent_xml.items do
  items.each do |item|  
    api_partial parent_xml,item
  end      
end

parent_xml.related do
  
end