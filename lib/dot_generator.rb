module DotGenerator
  
  def to_svg thing
    tmpfile = Tempfile.new("#{thing.class.name}_dot")
    file = File.new(tmpfile.path,'w')
    file.puts to_dot(thing)
    file.close    
    puts "saved to tmp file: "+tmpfile.path
    `dot -Tsvg #{tmpfile.path}`
  end
  
  def to_png thing
    tmpfile = Tempfile.new("#{thing.class.name}_dot")
    file = File.new(tmpfile.path,'w')
    file.puts to_dot(thing)
    file.close    
    puts "saved to tmp file: "+tmpfile.path
    `dot -Tpng #{tmpfile.path}`
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