module DotGenerator
  
  FILL_COLOURS = {Sop=>"gold",Model=>"red",DataFile=>"cyan",Investigation=>"skyblue3",Study=>"chocolate",Assay=>"burlywood"}
  
  def to_dot thing, deep=false
    dot = dot_header "Investigation"
    
    if thing.instance_of?(Investigation)
      dot += to_dot_inv thing,deep
    end
    
    if thing.instance_of?(Study)
      dot += to_dot_study thing
    end
    
    if thing.instance_of?(Assay)
      dot += to_dot_assay thing
    end
    
    dot << "}"
    return dot
  end
  
  def to_dot_inv investigation, show_assets=false
    dot = ""
    dot << "Inv_#{investigation.id} [label=\"#{multiline(investigation.title)}\",tooltip=\"#{tooltip(investigation)}\",shape=box,style=filled,fillcolor=#{FILL_COLOURS[Investigation]},URL=\"#{polymorphic_path(investigation)}\",target=\"_top\"];\n"
    investigation.studies.each do |s|
      dot << to_dot_study(s,show_assets)
      dot << "Inv_#{investigation.id} -- Study_#{s.id}\n"
    end
    return dot
  end
  
  def to_dot_study study, show_assets=true
    dot = ""
    dot << "Study_#{study.id} [label=\"#{multiline(study.title)}\",tooltip=\"#{tooltip(study)}\",shape=box,style=filled,fillcolor=#{FILL_COLOURS[Study]},URL=\"#{polymorphic_path(study)}\",target=\"_top\"];\n"
    study.assays.each do |assay|
      dot << to_dot_assay(assay, show_assets)
      dot << "Study_#{study.id} -- Assay_#{assay.id}\n"
    end
    return dot  
  end
  
  def to_dot_assay assay, show_assets=true
    dot = ""
    dot << "Assay_#{assay.id} [label=\"#{multiline(assay.title)}\",tooltip=\"#{tooltip(assay)}\",shape=folder,style=filled,fillcolor=#{FILL_COLOURS[Assay]},URL=\"#{polymorphic_path(assay)}\",target=\"_top\"];\n"    
    if (show_assets) 
      assay.assay_assets.each do |assay_asset|
        asset=assay_asset.asset
        asset_type=asset.resource.class.name
        if Authorization.is_authorized?("view",nil,asset,current_user)
          title = multiline(asset.resource.title)
          title = "#{asset.resource.class.name.upcase}: #{title}" unless title.downcase.starts_with?(asset.resource.class.name.downcase)
          dot << "Asset_#{asset.resource.id} [label=\"#{title}\",tooltip=\"#{tooltip(asset.resource)}\",shape=box,fontsize=7,style=filled,fillcolor=#{FILL_COLOURS[asset.resource.class]},URL=\"#{polymorphic_path(asset.resource)}\",target=\"_top\"];\n"
          label=""
          if assay_asset.relationship_type
            label = " [label=\"#{assay_asset.relationship_type.title}\" fontsize=9]"
          end
          dot << "Assay_#{assay.id} -- Asset_#{asset.resource.id} #{label} \n"
        else
          dot << "Asset_#{asset.resource.id} [label=\"Hidden Item\",tooltip=\"Hidden Item\",shape=box,fontsize=6,style=filled,fillcolor=lightgray];\n"
          dot << "Assay_#{assay.id} -- Asset_#{asset.resource.id}\n"
        end
      end
    end  
    return dot
  end
  
  def tooltip resource
    resource.title.strip
  end
  
  def to_svg thing,deep=false
    tmpfile = Tempfile.new("#{thing.class.name}_dot")
    file = File.new(tmpfile.path,'w')
    file.puts to_dot(thing,deep)
    file.close    
    post_process_svg(`dot -Tsvg #{tmpfile.path}`)
  end
  
  def dot_header title
    dot = "graph #{title} {"
    dot << "rankdir = LR;"    
    dot << "splines = line;"
    dot << "node [fontsize=9,fontname=\"Helvetica\"];"    
    dot << "bgcolor=white;" 
    dot << "edge [arrowsize=0.6];\n" 
    return dot
  end
  
  def to_png thing,deep=false
    tmpfile = Tempfile.new("#{thing.class.name}_dot")
    file = File.new(tmpfile.path,'w')
    file.puts to_dot(thing,deep)
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
    new_str=str[0..80]
        
    word_arr=new_str.split
    x=line_len
    while x<new_str.split.length do
      word_arr.insert(x,"\\n")
      x+=line_len+1
    end
    
    end_str = (new_str.length!=str.length) ? " ..." : ""
    (word_arr.join(" ") + end_str).strip   
  end
  
end
