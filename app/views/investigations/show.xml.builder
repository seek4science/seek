xml.instruct! :xml
render :partial=>"investigations/api/investigation",:locals=>{:investigation=>@investigation,:parent_xml => xml,:is_root=>true}