xml.instruct! :xml
render :partial=>"organisms/api/organism",:locals=>{:organism=>@organism,:parent_xml => xml,:is_root=>true}