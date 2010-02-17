module ResourceListItemHelper
  
  
  def get_list_item_content_partial resource
    return get_original_model_name(resource).pluralize.underscore + "/resource_list_item"
  end
  
  def get_list_item_actions_partial resource
    if resource.respond_to?("asset")
      actions_partial = "assets/resource_actions_td"
    else
      actions_partial = nil
    end
    return actions_partial
  end
  
  def get_list_item_avatar_partial resource
    if resource.respond_to?("asset")
      actions_partial = "layouts/asset_resource_avatars"
    else
      actions_partial = "layouts/resource_avatar"
    end
    return actions_partial
  end
  
  def list_item_title resource, title=nil, url=nil    
    if title.nil?
      title = get_object_title(resource)
    end    
    name = resource.class.name.split("::")[0]
    case name
    when "DataFile","Model","Sop"
      image = image_tag(((name == "Model") ? icon_filename_for_key("model_avatar"): (file_type_icon_url(resource))), :style => "width: 24px; height: 24px; vertical-align: middle")
      icon = link_to_draggable(image, show_resource_path(resource), :id=>model_to_drag_id(resource), :class=> "asset", :title=>tooltip_title_attrib(get_object_title(resource)))
      return "<p class=\"list_item_title\">#{icon} #{link_to title, (url.nil? ? show_resource_path(resource) : url)}</p>"
    when "Person"
      return "<p class=\"list_item_title\">#{link_to title, (url.nil? ? show_resource_path(resource) : url)} #{admin_icon(resource) + " " + pal_icon(resource)}</p>"
    else
      return "<p class=\"list_item_title\">#{link_to title, (url.nil? ? show_resource_path(resource) : url)}</p>"
    end
  end
  
  def list_item_simple_list items, attribute
    html = "<p class=\"list_item_attribute\"><b>#{(items.size > 1 ? attribute.pluralize : attribute)}:</b> "
    if items.empty?
      html << "<span class='none_text'>Not specified</span>"
    else
      items.each do |i|
        if block_given?
          value = yield(i)
        else
          value = (link_to get_object_title(i), show_resource_path(i))
        end
        html << value + (i == items.last ? "" : ", ")
      end
    end
    return html + "</p>"
  end  
  
  def list_item_authorized_list items, attribute, sort=true, max_length=75, count_hidden_items=false
    html = "<p class=\"list_item_attribute\"><b>#{(items.size > 1 ? attribute.pluralize : attribute)}:</b> "
    items = Authorization.authorize_collection("view", items, current_user,count_hidden_items)
    if items.empty?
      html << "<span class='none_text'>No #{attribute}</span>"
    else
      original_size = items.size
      items = items.compact
      hidden_item_count = original_size - items.size
      items = items.sort{|a,b| get_object_title(a)<=>get_object_title(b)} if sort
      items.each do |i|
        html << (link_to h(truncate(i.title,:length=>max_length)), show_resource_path(i), :title=>get_object_title(i))
        html << ", " unless items.last==i
      end
      if count_hidden_items && hidden_item_count>0
        html << "<span class=\"none_text\">#{items.size > 0 ? " and " : ""}#{hidden_item_count} hidden #{hidden_item_count > 1 ? "items":"item"}</span>"
      end
    end
    return html + "</p>"
  end
 
  def list_item_attribute attribute, value, url=nil
    unless url.nil?
      value = link_to value, url
    end
    return "<p class=\"list_item_attribute\"><b>#{attribute}</b>: #{value}</p>"
  end
  
  def list_item_optional_attribute attribute, value, url=nil, missing_value_text="Not specified"
    if value.blank?
      value = "<span class='none_text'>#{missing_value_text}</span>"
    else
      unless url.nil?
        value = link_to value, url
      end
    end
    return missing_value_text.nil? ? "" : "<p class=\"list_item_attribute\"><b>#{attribute}</b>: #{value}</p>"
  end
  
  def list_item_timestamp resource
    html = "<p class=\"list_item_attribute\"><b>Created:</b> " + resource.created_at.strftime('%d/%m/%Y @ %H:%M:%S')
    unless resource.created_at == resource.updated_at         
      html << " <b>Last updated:</b> " + resource.updated_at.strftime('%d/%m/%Y @ %H:%M:%S')
    end
    html << "</p>"
    return html
  end
  
  def list_item_description text, auto_link=true, length=500
    html = "<div class=\"list_item_desc\">"
    html << text_or_not_specified(text, :description => true,:auto_link=>auto_link, :length=>length)
    html << "</div>"
    return html    
  end
  
  def list_item_contributor resource
    if resource.contributor.nil?
      value = "JERM harvester"
    else
      value = link_to resource.contributor.person.name, resource.contributor
    end
    return "<p class=\"list_item_attribute\"><b>Uploader</b>: #{value}</p>"
  end
  
end