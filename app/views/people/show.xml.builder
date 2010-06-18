xml.instruct! :xml
render :partial=>"people/api/person",:locals=>{:person=>@person,:parent_xml => xml,:is_root=>true}