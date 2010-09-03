module DotGenerator
  
  FILL_COLOURS = {Sop=>"cadetblue2",Model=>"yellow3",DataFile=>"darkgoldenrod2",Investigation=>"#C7E9C0",Study=>"#91c98b",Assay=>"#64b466"}
  HIGHLIGHT_ATTRIBUTE="color=blue,penwidth=4," #trailing comma is required
  
  def to_dot root_item, deep=false, current_item=nil
    current_item||=root_item
    dot = dot_header "Investigation"
    
    if root_item.instance_of?(Investigation)
      dot += to_dot_inv root_item,deep,current_item
    end
    
    if root_item.instance_of?(Study)
      dot += to_dot_study root_item,deep,current_item
    end
    
    if root_item.instance_of?(Assay)
      dot += to_dot_assay root_item,deep,current_item
    end
    
    dot << "}"
    return dot
  end
  
  def to_dot_inv investigation, show_assets=false,current_item=nil
    current_item||=investigation
    dot = ""
    highlight_attribute=HIGHLIGHT_ATTRIBUTE if investigation==current_item
    dot << "Inv_#{investigation.id} [label=\"#{multiline(investigation.title)}\",tooltip=\"#{tooltip(investigation)}\",shape=box,style=filled,fillcolor=\"#{FILL_COLOURS[Investigation]}\",#{highlight_attribute}URL=\"#{polymorphic_path(investigation)}\",target=\"_top\"];\n"
    investigation.studies.each do |s|
      dot << to_dot_study(s,show_assets,current_item)
      dot << "Inv_#{investigation.id} -- Study_#{s.id}\n"
    end
    return dot
  end
  
  def to_dot_study study, show_assets=true,current_item=nil
    current_item||=study
    dot = ""
    
    highlight_attribute=HIGHLIGHT_ATTRIBUTE if study==current_item
    
    dot << "Study_#{study.id} [label=\"#{multiline(study.title)}\",tooltip=\"#{tooltip(study)}\",shape=box,style=filled,fillcolor=\"#{FILL_COLOURS[Study]}\",#{highlight_attribute}URL=\"#{polymorphic_path(study)}\",target=\"_top\"];\n"
    study.assays.each do |assay|
      dot << to_dot_assay(assay, show_assets,current_item)
      dot << "Study_#{study.id} -- Assay_#{assay.id}\n"
    end
    return dot  
  end
  
  def to_dot_assay assay, show_assets=true,current_item=nil
    current_item||=assay
    dot = ""    
    highlight_attribute=HIGHLIGHT_ATTRIBUTE if assay==current_item
    dot << "Assay_#{assay.id} [label=\"#{multiline(assay.title)}\",tooltip=\"#{tooltip(assay)}\",shape=folder,style=filled,fillcolor=\"#{FILL_COLOURS[Assay]}\",#{highlight_attribute}URL=\"#{polymorphic_path(assay)}\",target=\"_top\"];\n"    
    if (show_assets) 
      assay.assay_assets.each do |assay_asset|
        asset=assay_asset.asset
        asset_type=asset.class.name
        if asset_type.end_with?("::Version")
          asset = asset.parent
          asset_type = asset.class.name
        end
        if Authorization.is_authorized?("view",nil,asset,current_user)
          title = multiline(asset.title)
          title = "#{asset_type.upcase}: #{title}" unless title.downcase.starts_with?(asset_type.downcase)
          dot << "Asset_#{asset.id} [label=\"#{title}\",tooltip=\"#{tooltip(asset)}\",shape=box,fontsize=7,style=filled,fillcolor=\"#{FILL_COLOURS[asset.class]}\",URL=\"#{polymorphic_path(asset)}\",target=\"_top\"];\n"
          label=""
          if assay_asset.relationship_type
            label = " [label=\"#{assay_asset.relationship_type.title}\" fontsize=9]"
          end
          dot << "Assay_#{assay.id} -- Asset_#{asset.id} #{label} \n"
        else
          dot << "Asset_#{asset.id} [label=\"Hidden Item\",tooltip=\"Hidden Item\",shape=box,fontsize=6,style=filled,fillcolor=lightgray];\n"
          dot << "Assay_#{assay.id} -- Asset_#{asset.id}\n"
        end
      end
    end  
    return dot
  end
  
  def tooltip resource
    resource.class.name.upcase + ": " + resource.title.strip
  end
  
  def to_svg root_item,deep=false,current_item=nil
    current_item||=root_item
    tmpfile = Tempfile.new("#{root_item.class.name}_dot")
    file = File.new(tmpfile.path,'w')
    file.puts to_dot(root_item,deep,current_item)
    file.close    
    post_process_svg(`dot -Tsvg #{tmpfile.path}`)
  end
  
  def dot_header title
    dot = "graph #{title} {"
    dot << "rankdir = LR;"    
    dot << "splines = spline;"
    dot << "node [fontsize=9,fontname=\"Helvetica\"];"    
    dot << "bgcolor=transparent;" 
    dot << "edge [arrowsize=0.6];\n" 
    return dot
  end
  
  def to_png root_item,deep=false
    tmpfile = Tempfile.new("#{root_item.class.name}_dot")
    file = File.new(tmpfile.path,'w')
    file.puts to_dot(root_item,deep)
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
