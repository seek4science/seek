xml.instruct! :xml

xml.tag! "assays",xlink_attributes(uri_for_collection("assays", :params => params)), 
xml_root_attributes,
         :resourceType => "Assays" do
  
  xml.parameters do
    
  end
  
  xml.statistics do
    
  end
  
  xml.results do
    @assays.each do |assay|
      render :partial=>"assays/api/assay",:locals=>{:assay=>assay,:parent_xml => xml,:is_root=>false}
    end      
  end
  
  xml.related do
    
  end
end