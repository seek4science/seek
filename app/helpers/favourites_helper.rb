module FavouritesHelper
  def model_to_drag_id object
    if object.class.name.include?("::Version")
      object = object.parent
    end
    model_name=object.class.to_s
    return "drag_"+model_name+"_"+object.id.to_s+"_"+object.object_id.abs.to_s
  end

  def fav_line_tag favourite
    fav_image_tag(favourite) + "<span class='fav_title'>#{h(favourite.resource.title)}</span>"
  end
  
  def fav_image_tag favourite
    item = favourite.resource
    title = get_object_title(item)
    
    tiny_image = ""
    case item.class.name.downcase
    when "datafile", "sop"
      tiny_image = image_tag(file_type_icon_url(item), :class=>"fav_icon")
    when "model","investigation","study","assay"
      tiny_image = image "#{item.class.name.downcase}_avatar", :class=>"fav_icon"
    when "person", "project", "institution"
      if (item.avatar_selected?)
        tiny_image = image_tag avatar_url(item, item.avatar_id, 32), :alt=> h(title), :class => 'fav_icon'
      else
        tiny_image = default_avatar(item.class.name, 32, h(title))
      end
    when "savedsearch"
      tiny_image = image "saved_search", :class=>"fav_icon"
    end
    
    image_tag_code = tiny_image #avatar(item, 24, true)

    return link_to_draggable(image_tag_code, show_resource_path(item), :title=>tooltip_title_attrib(title),:class=>"favourite", :id=>"fav_#{favourite.id}")
  end
  
  def favourite_drag_element drag_id
    return draggable_element(drag_id, :revert=>true, :ghosting=>false)
  end
  
  #an avatar with an image_tag_for_key in the corner to show it can be favourited
  def favouritable_icon(item, size=100)
    #the image_tag_for_key:
    html = avatar(item, size, true)    
    html = "<div class='favouritable_icon'>#{html}</div>"

    html = link_to_draggable(html, show_resource_path(item), :id=>model_to_drag_id(item), :class=> "asset", :title=>tooltip_title_attrib(get_object_title(item)))
    return html
  end 
  
  private
end
