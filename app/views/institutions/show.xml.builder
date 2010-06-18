xml.instruct! :xml
render :partial=>"institutions/api/institution",:locals=>{:institution=>@institution,:parent_xml => xml,:is_root=>true}