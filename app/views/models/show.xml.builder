xml.instruct! :xml
render :partial=>"models/api/model",:locals=>{:model=>@display_model,:parent_xml => xml,:is_root=>true}