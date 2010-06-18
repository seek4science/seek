xml.instruct! :xml
render :partial=>"models/api/model",:locals=>{:model=>@model,:parent_xml => xml,:is_root=>true}