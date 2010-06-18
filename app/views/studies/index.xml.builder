xml.instruct! :xml

xml.tag! "studies",xlink_attributes(uri_for_collection("studies", :params => params)), 
xml_root_attributes,
         :resourceType => "Studies" do
  
  xml.parameters do
    
  end
  
  xml.statistics do
    
  end
  
  xml.results do
    @studies.each do |study|
      render :partial=>"studies/api/study",:locals=>{:study=>study,:parent_xml => xml,:is_root=>false}
    end      
  end
  
  xml.related do
    
  end
end