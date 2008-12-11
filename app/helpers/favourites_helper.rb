module FavouritesHelper
  def model_to_drag_id object
    model_name=object.class.to_s
    return "drag_"+model_name+"_"+object.id.to_s
  end
  
  def fav_image_tag favourite
    item = favourite.model_name.constantize.find(favourite.asset_id)
    image_tag_code = avatar(item, 32, true)
    
    title = ""
    if ["Person", "Institution", "Project"].include? item.class.name
      title = h(item.name)
    end
    
    return link_to_draggable(image_tag_code, url_for(item), :title=>tooltip_title_attrib(title),:class=>"favourite", :id=>"fav_#{favourite.id}")
  end
  
  def favourite_drag_element drag_id
    return draggable_element(drag_id, :revert=>true, :ghosting=>false)
  end
  
  private
  
end
