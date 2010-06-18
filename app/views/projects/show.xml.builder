xml.instruct! :xml
render :partial=>"projects/api/project",:locals=>{:project=>@project,:parent_xml => xml,:is_root=>true}