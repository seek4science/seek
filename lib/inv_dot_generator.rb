module InvDotGenerator
  def to_dot
    dot = "digraph Investigation {"
    
    dot << "compound=true;" 
    dot << "node [fontsize=8];"    
    dot << "bgcolor=white;" 
    dot << "edge [arrowsize=1, color=black];"
    
    dot << "AAA [label=\"blah blah\\n blah blah blah\",shape=box];"
    dot << "BBB [label=\"blah blah\\n blah blah blah\",shape=box];"
    dot << "AAA -> BBB;\n"
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
    
end