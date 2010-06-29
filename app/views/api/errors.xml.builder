xml.instruct! :xml


# <errors>
xml.tag! "errors",xml_root_attributes do
  
  xml.error do
    xml.status status 
    xml.message message
  end
  
end