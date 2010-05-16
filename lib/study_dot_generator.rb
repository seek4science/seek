module StudyDotGenerator
  def to_dot
    dot = "graph Study {"
    dot << "rankdir = LR;"    
    dot << "node [fontsize=8];"    
    dot << "bgcolor=white;" 
    dot << "edge [arrowsize=0.6];\n"   
    dot << "Study_#{id} [label=\"#{multiline(title)}\",shape=box,style=filled,fillcolor=skyblue3];\n"
    assays.each do |a|
      dot << "Assay_#{a.id} [label=\"#{multiline(a.title)}\",shape=box,style=filled,fillcolor=skyblue1];\n"
      dot << "Study_#{id} -- Assay_#{a.id}\n"
      a.assets.each do |asset|
        dot << "Asset_#{asset.id} [label=\"#{multiline(asset.title)}\",shape=ellipse,style=filled,fillcolor=cyan];\n"
        dot << "Assay_#{a.id} -- Asset_#{asset.id}\n"
      end    
    end    
    dot << "}"
    return dot
  end
  
  def to_svg
    tmpfile = Tempfile.new('study_dot')
    file = File.new(tmpfile.path,'w')
    file.puts to_dot
    file.close    
    puts "saved to tmp file: "+tmpfile.path
    `dot -Tsvg #{tmpfile.path}`
  end
  
  def multiline str,line_len=3    
    str=str[0..70]
    str+=" ..."
    word_arr=str.split
    x=line_len
    while x<str.split.length do
      word_arr.insert(x,"\\n")
      x+=line_len
    end
    
    word_arr.join(" ")
  end
  
end