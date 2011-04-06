require 'libxml'

module DotGenerator
  
  FILL_COLOURS = {Sop=>"cadetblue3",
                  Model=>"yellow3",
                  DataFile=>"burlywood2",
                  Investigation=>"#C7E9C0",
                  Study=>"#91c98b",
                  Assay=>"#64b466",
                  Publication=>"#84B5FD"
                  }
  HIGHLIGHT_ATTRIBUTE="color=blue,penwidth=2," #trailing comma is required
  
  def dot_header title
    dot = "graph #{title} {"
    dot << "rankdir = LR;\n"    
    dot << "splines = line;\n"
    dot << "node [fontsize=9,fontname=\"Helvetica\"];\n"    
    dot << "bgcolor=transparent;\n"
    dot << "ranksep=0.2;\n"
    dot << "edge [arrowsize=0.6];\n" 
    return dot
  end
  
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
    
    if root_item.instance_of?(DataFile) ||
      root_item.instance_of?(Model) ||
      root_item.instance_of?(Sop)
      root_item.assays.each do |assay|
        dot += to_dot_assay assay,deep,current_item
      end
      if root_item.assays.empty?
        dot += to_dot_asset root_item,current_item
      end
    end
    
    if root_item.instance_of?(Publication)
      dot << to_dot_publication(root_item,current_item)
      root_item.related_assays.each do |assay|
        dot += to_dot_assay assay,deep,current_item
        dot << "Assay_#{assay.id} -- Publication_#{root_item.id}; \n"
      end
       (root_item.related_data_files + root_item.related_models).each do |asset|
        dot += to_dot_asset asset,current_item
      end
    end    
    dot << "}"
    return dot
  end
  
  def to_dot_inv investigation, show_assets=false,current_item=nil
    current_item||=investigation
    dot = ""
    highlight_attribute=HIGHLIGHT_ATTRIBUTE if investigation==current_item
    dot << "Investigation_#{investigation.id} [label=\"#{multiline(investigation.title)}\",width=2,tooltip=\"#{tooltip(investigation)}\",shape=box,style=filled,fillcolor=\"#{FILL_COLOURS[Investigation]}\",#{highlight_attribute}URL=\"#{polymorphic_path(investigation)}\",target=\"_top\"];\n"
    investigation.studies.each do |s|
      dot << to_dot_study(s,show_assets,current_item)
      dot << "Investigation_#{investigation.id} -- Study_#{s.id}\n"
    end
    return dot
  end
  
  def to_dot_study study, show_assets=true,current_item=nil
    current_item||=study
    dot = ""
    
    highlight_attribute=HIGHLIGHT_ATTRIBUTE if study==current_item
    
    dot << "Study_#{study.id} [label=\"#{multiline(study.title)}\",width=2,tooltip=\"#{tooltip(study)}\",shape=box,style=filled,fillcolor=\"#{FILL_COLOURS[Study]}\",#{highlight_attribute}URL=\"#{polymorphic_path(study)}\",target=\"_top\"];\n"
    study.assays.each do |assay|
      dot << to_dot_assay(assay, show_assets,current_item)
      dot << "Study_#{study.id} -- Assay_#{assay.id}; \n"
    end
    return dot  
  end
  
  def to_dot_assay assay, show_assets=true,current_item=nil
    current_item||=assay
    dot = ""
    highlight_attribute=HIGHLIGHT_ATTRIBUTE if assay==current_item
    dot << "Assay_#{assay.id} [label=\"#{multiline(assay.title)}\",width=2,tooltip=\"#{tooltip(assay)}\",shape=folder,style=filled,fillcolor=\"#{FILL_COLOURS[Assay]}\",#{highlight_attribute}URL=\"#{polymorphic_path(assay)}\",target=\"_top\"];\n"    
    if (show_assets)            
      assay.assay_assets.each do |assay_asset|
        dot << to_dot_asset(assay_asset.versioned_asset, current_item)
        label=""
        if assay_asset.relationship_type
          label = " [label=\"#{assay_asset.relationship_type.title}\" fontsize=9]"
        end   
        dot << "Assay_#{assay.id} -- #{assay_asset.asset_type}_#{assay_asset.asset_id} #{label} ;\n"        
      end
      assay.related_publications.each do |publication|
        dot << to_dot_publication(publication, current_item)
        dot << "Assay_#{assay.id} -- Publication_#{publication.id}; \n"        
      end            
    end  
    
    return dot
  end
  
  def to_dot_asset asset, current_item=nil
    current_item||=asset
    
    show_publications = current_item.respond_to?("contributor")
    dot = ""    
    highlight_attribute=HIGHLIGHT_ATTRIBUTE if asset==current_item || (asset.class.name.end_with?("::Version") && asset.parent==current_item)
    asset_type=asset.class.name
    version = asset.version
    if asset_type.end_with?("::Version")
      asset = asset.parent
      asset_type = asset.class.name
    end
    if Authorization.is_authorized?("view",nil,asset,current_user)
      title = multiline(asset.title)      
      title = "#{asset_type.upcase}\\n #{title}" unless title.downcase.starts_with?(asset_type.downcase)
      dot << "#{asset.class.name}_#{asset.id} [label=\"#{title}\",width=2,tooltip=\"#{tooltip(asset)}\",shape=box,fontsize=7,style=filled,fillcolor=\"#{FILL_COLOURS[asset.class]}\",#{highlight_attribute}URL=\"#{polymorphic_path(asset,:version=>version)}\",target=\"_top\"];\n"
      if show_publications
        asset.related_publications.each do |publication|
          dot << to_dot_publication(publication, current_item)
          dot << "#{asset.class.name}_#{asset.id} -- Publication_#{publication.id}; \n"          
        end
      end
    else
      dot << "#{asset.class.name}_#{asset.id} [label=\"Hidden Item\",width=2,tooltip=\"Hidden Item\",shape=box,fontsize=6,style=filled,fillcolor=lightgray];\n"
    end
    
    return dot    
  end
  
  def to_dot_publication publication, current_item=nil
    current_item||=publication
    highlight_attribute=HIGHLIGHT_ATTRIBUTE if publication==current_item
    title = multiline(publication.title)
    title = "PUBLICATION\\n #{title}"
    dot = "Publication_#{publication.id} [label=\"#{title}\",width=2,tooltip=\"#{tooltip(publication)}\",shape=box,fontsize=7,style=filled,fillcolor=\"#{FILL_COLOURS[Publication]}\",#{highlight_attribute}URL=\"#{polymorphic_path(publication)}\",target=\"_top\"];\n"
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

  def to_png root_item,deep=false,current_item=nil
    tmpfile = Tempfile.new("#{root_item.class.name}_dot")
    file = File.new(tmpfile.path,'w')
    file.puts to_dot(root_item,deep,current_item)
    file.close    
    puts "saved to tmp file: "+tmpfile.path
    `dot -Tpng #{tmpfile.path}`
  end
  
  #fixes a problem with missing units, which causes Firefox to incorrectly display.
  #this will fail if the font-size set is not a whole integer  
  def post_process_svg svg
    svg = svg.gsub(".00;",".00px;")
    orig_header = svg.match(/<svg([^>]*)>/).to_s #remember header with namespace
    
    parser = LibXML::XML::Parser.string(svg)
    document = parser.parse
    document.root.namespaces.default_prefix = 'svg'
    document.find("svg:g//svg:g").each do |node|
      title = node.find_first("svg:title").content
      unless title.include?("--")
        object_class,object_id = title.split("_")        
        if ["Sop","Model","DataFile","Publication","Study","Assay","Investigation"].include?(object_class)
          a = node.find_first(".//svg:a")          
          polygon = a.find_first(".//svg:polygon")
          points = polygon.attributes["points"]
          points = points.split(" ")
          x2 = nil
          y2 = nil
          if points.size == 5
            x2,y2 = points[1].split(",")
          else
            x2,y2 = points[4].split(",")
          end
          #ADD THE CORRECT AVATAR, HERE
          if self.respond_to?("avatar")
            object = eval("#{object_class}.find(#{object_id})")
            av_url = avatar(object, 14, true).match(/src=\"[^\"]*\"/).to_s.gsub("src=","").gsub("\"","")
            rect_node = LibXML::XML::Node.new("rect width=\"18\" height=\"18\" x=\"#{x2.to_f + 3}\" y=\"#{y2.to_f + 3}\" style=\"fill: rgb(255,255,255);stroke:rgb(120,120,120);\"")
            image_node = LibXML::XML::Node.new("image width=\"14\" height=\"14\" x=\"#{x2.to_f + 5}\" y=\"#{y2.to_f + 5}\" xlink:href=\"#{av_url}\"")
            a.add_element(rect_node)
            a.add_element(image_node)
          end
          
        end
      end
    end
    
    svg_el = document.find_first("//svg:svg")
    svg_el.attributes["width"]="500pt"    
    svg = document.to_s
        
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
