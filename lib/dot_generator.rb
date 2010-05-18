module DotGenerator
  
  def to_svg thing
    tmpfile = Tempfile.new("#{thing.class.name}_dot")
    file = File.new(tmpfile.path,'w')
    file.puts to_dot(thing)
    file.close    
    puts "saved to tmp file: "+tmpfile.path
    post_process_svg(`dot -Tsvg #{tmpfile.path}`)
  end
  
  def dot_header title
    dot = "graph #{title} {"
    dot << "rankdir = LR;"    
    dot << "node [fontsize=9,fontname=\"Helvetica\"];"    
    dot << "bgcolor=white;" 
    dot << "edge [arrowsize=0.6];\n" 
    return dot
  end
  
  def to_png thing
    tmpfile = Tempfile.new("#{thing.class.name}_dot")
    file = File.new(tmpfile.path,'w')
    file.puts to_dot(thing)
    file.close    
    puts "saved to tmp file: "+tmpfile.path
    `dot -Tpng #{tmpfile.path}`
  end
  
  #fixes a problem with missing units, which causes Firefox to incorrectly display.
  #this will fail if the font-size set is not a whole integer  
  def post_process_svg svg
    return svg.gsub(".00;",".00px;")
  end
  
  def multiline str,line_len=3    
    new_str=str[0..500]
    str+=" ..." if str.length>500
    word_arr=new_str.split
    x=line_len
    while x<new_str.split.length do
      word_arr.insert(x,"\\n")
      x+=line_len+1
    end
    
    word_arr.join(" ")
  end
  
end