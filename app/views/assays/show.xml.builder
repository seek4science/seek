xml.instruct! :xml
render :partial=>"assays/api/assay",:locals=>{:assay=>@assay,:parent_xml => xml,:is_root=>true}