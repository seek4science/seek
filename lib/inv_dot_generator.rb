module InvDotGenerator
  def to_dot
    dot = "digraph Investigation {"
    dot << "rankdir = LR;"    
    dot << "node [fontsize=10];"    
    dot << "bgcolor=white;" 
    dot << "edge [arrowsize=0.6];\n"   
    dot << "Inv_#{id} [label=\"#{multiline(title)}\",shape=box,style=filled,fillcolor=skyblue3];\n"
    studies.each do |s|
      dot << "Study_#{s.id} [label=\"#{multiline(s.title)}\",shape=box,style=filled,fillcolor=skyblue2];\n"
      dot << "Inv_#{id} -> Study_#{s.id}\n"
      s.assays.each do |a|
        dot << "Assay_#{a.id} [label=\"#{multiline(a.title)}\",shape=box,style=filled,fillcolor=skyblue1];\n"
      dot << "Study_#{s.id} -> Assay_#{a.id}\n"
      end
    end
    
    dot << "}"
    return dot
  end
  
  def to_svg
    tmpfile = Tempfile.new('investigation_dot')
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