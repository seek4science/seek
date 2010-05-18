module InvDotGenerator
  include DotGenerator
  def to_dot investigation
    dot = dot_header "Investigation"
     
    dot << "Inv_#{investigation.id} [label=\"#{multiline(investigation.title)}\",tooltip=\"#{investigation.title}\",shape=box,style=filled,fillcolor=skyblue3,URL=\"#{investigation_path(investigation)}\",target=\"_top\"];\n"
    investigation.studies.each do |s|
      dot << "Study_#{s.id} [label=\"#{multiline(s.title)}\",tooltip=\"#{s.title}\",shape=box,style=filled,fillcolor=skyblue2,URL=\"#{study_path(s)}\",target=\"_top\"];\n"
      dot << "Inv_#{investigation.id} -- Study_#{s.id}\n"
      s.assays.each do |a|
        dot << "Assay_#{a.id} [label=\"#{multiline(a.title)}\",tooltip=\"#{a.title}\",shape=box,style=filled,fillcolor=skyblue1,URL=\"#{assay_path(a)}\",target=\"_top\"];\n"
      dot << "Study_#{s.id} -- Assay_#{a.id}\n"
      end
    end
    
    dot << "}"
    return dot
  end
  
  
    
end