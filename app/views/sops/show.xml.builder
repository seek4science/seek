xml.instruct! :xml
render :partial=>"sops/api/sop",:locals=>{:sop=>@display_sop,:parent_xml => xml,:is_root=>true}