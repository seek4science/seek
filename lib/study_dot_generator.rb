module StudyDotGenerator
  include DotGenerator
  def to_dot study
    dot = "graph Study {"
    dot << "rankdir = LR;"    
    dot << "node [fontsize=10,fontname=\"Helvetica\"];"
    dot << "bgcolor=white;" 
    dot << "edge [arrowsize=0.6];\n"   
    dot << "Study_#{study.id} [label=\"#{multiline(study.title)}\",shape=box,style=filled,fillcolor=skyblue3,URL=\"#{study_path(study)}\"];\n"
    study.assays.each do |a|
      dot << "Assay_#{a.id} [label=\"#{multiline(a.title)}\",shape=box,style=filled,fillcolor=skyblue1,URL=\"#{assay_path(a)}\"];\n"
      dot << "Study_#{study.id} -- Assay_#{a.id}\n"
#      a.assets.each do |asset|
#        if Authorization.is_authorized?("view",nil,asset,current_user)
#          dot << "Asset_#{asset.id} [label=\"#{multiline(asset.title)}\",shape=ellipse,style=filled,fillcolor=cyan];\n"
#          dot << "Assay_#{a.id} -- Asset_#{asset.id}\n"
#        end
#      end    
    end    
    dot << "}"
    return dot
  end
  
  
  
end