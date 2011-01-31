is_root = false unless local_assigns.has_key?(:is_root)

parent_xml.tag! "event",
  core_xlink(event).merge(is_root ? xml_root_attributes : {}) do

  render :partial=>"api/standard_elements",:locals=>{:parent_xml => parent_xml,:is_root=>is_root,:object=>event}
  if (is_root)
    [:start_date,:end_date,:url,:city,:country,:address].each do |sym|
      parent_xml.tag! sym.to_s,event.send(sym)
    end
    associated_resources_xml parent_xml,event
  end
end