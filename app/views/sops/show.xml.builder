xml.instruct! :xml
render :partial=>"sops/api/sop",:locals=>{:sop=>@sop,:parent_xml => xml,:is_root=>true}