xml.instruct! :xml
render :partial=>"studies/api/study",:locals=>{:study=>@study,:parent_xml => xml,:is_root=>true}