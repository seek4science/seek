xml.instruct! :xml
render :partial=>"publications/api/publication",:locals=>{:publication=>@publication,:parent_xml => xml,:is_root=>true}