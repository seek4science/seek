xml.instruct! :xml
render :partial=>"strains/api/strain",:locals=>{:assay=>@strain,:parent_xml => xml,:is_root=>true}