module InvDotGenerator
  include DotGenerator
  def to_dot investigation
    dot = "graph Investigation {"
    dot << "rankdir = LR;"    
    dot << "node [fontsize=10,fontname=\"Helvetica\"];"    
    dot << "bgcolor=white;" 
    dot << "edge [arrowsize=0.6];\n"   
    dot << "Inv_#{investigation.id} [label=\"#{multiline(investigation.title)}\",tooltip=\"#{investigation.title}\",shape=box,style=filled,fillcolor=skyblue3,URL=\"#{investigation_path(investigation)}\"];\n"
    investigation.studies.each do |s|
      dot << "Study_#{s.id} [label=\"#{multiline(s.title)}\",tooltip=\"#{s.title}\",shape=box,style=filled,fillcolor=skyblue2,URL=\"#{study_path(s)}\"];\n"
      dot << "Inv_#{investigation.id} -- Study_#{s.id}\n"
      s.assays.each do |a|
        dot << "Assay_#{a.id} [label=\"#{multiline(a.title)}\",tooltip=\"#{a.title}\",shape=box,style=filled,fillcolor=skyblue1,URL=\"#{assay_path(a)}\"];\n"
      dot << "Study_#{s.id} -- Assay_#{a.id}\n"
      end
    end
    
    dot << "}"
    return dot
  end
  
  
    
end