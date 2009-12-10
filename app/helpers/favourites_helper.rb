module FavouritesHelper
  def model_to_drag_id object
    model_name=object.class.to_s
    return "drag_"+model_name+"_"+object.id.to_s+"_"+object.object_id.abs.to_s
  end
  
  def fav_image_tag favourite
    item = favourite.resource
    title = get_object_title(item)
    
    tiny_image = ""
    case item.class.name.downcase
      when "datafile", "sop"   
        tiny_image = image_tag(file_type_icon_url(item), :style => "padding: 11px; border:1px solid #{item.class.name == "Sop" ? "#CCCCFF" : "#FFCCCC"};background-color:#FFFFFF;")
      when "model"
        tiny_image = image_tag "/images/famfamfam_silk/bricks.png", :style => "padding: 11px; border:1px solid #CCCCCC;background-color:#FFFFFF;"
      when "investigation"
        tiny_image = image_tag "/images/famfamfam_silk/magnifier.png", :style => "padding: 11px; border:1px solid #CCCCCC;background-color:#FFFFFF;"
      when "study"
        tiny_image = image_tag "/images/famfamfam_silk/book_open.png", :style => "padding: 11px; border:1px solid #CCCCCC;background-color:#FFFFFF;"
      when "assay"
        tiny_image = image_tag "/images/famfamfam_silk/report.png", :style => "padding: 11px; border:1px solid #CCCCCC;background-color:#FFFFFF;"
      when "person", "project", "institution"
        tiny_image = avatar(item, 32, true)
    end
    
    image_tag_code = tiny_image #avatar(item, 24, true)

    return link_to_draggable(image_tag_code, show_resource_path(item), :title=>tooltip_title_attrib(title),:class=>"favourite", :id=>"fav_#{favourite.id}")
  end
  
  def favourite_drag_element drag_id
    return draggable_element(drag_id, :revert=>true, :ghosting=>false)
  end
  
  #an avatar with an icon in the corner to show it can be favourited
  def favouritable_icon(item, size=100)
    #the icon:
    html = avatar(item, size, true)
    if ["DataFile","Model","Sop","Investigation","Study","Assay"].include?(item.class.name)
      floating_text = "<div class=\"avatar_text\" style=\"width:#{size+10}px;\">#{item.class.name.titleize}</div>"
    else
      floating_text = ""
    end  
    html = "<div style=\"width: #{size+10}px; height: #{size+10}px\" class=\"favouritable_icon\">#{html}#{floating_text}</div>"
    html = link_to_draggable(html, show_resource_path(item), :id=>model_to_drag_id(item), :class=> "asset", :title=>tooltip_title_attrib(get_object_title(item)))
    return html
  end 
  
  private
end
