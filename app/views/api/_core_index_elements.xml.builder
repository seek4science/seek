parent_xml.parameters do
  
end

parent_xml.statistics do
  
end

parent_xml.items do
  #partial_path = api_partial_path_for_item(collection.first) unless collection.empty?
  partial_path=api_partial_path_for_item(items.first) unless items.empty?
  items.each do |item|        
    render :partial=>partial_path,:locals=>{item.class.name.underscore.to_sym=>item,:parent_xml => parent_xml,:is_root=>false}
  end      
end

parent_xml.related do
  
end