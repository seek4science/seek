module ResourceListItemHelper
  
  
  def get_list_item_content_partial resource
    return get_original_model_name(resource).pluralize.underscore + "/resource_list_item"
  end
  
  def get_list_item_actions_partial resource
    name = resource.class.name.split("::")[0]
    case name
      when "DataFile","Model","Sop"
        actions_partial = "assets/resource_actions_td"
      else
        actions_partial = nil
    end
    return actions_partial
  end
  
  def list_item_title resource, title=nil, url=nil    
    if title.nil?
      title = get_object_title(resource)
    end    
    return "<p class=\"list_item_title\">#{link_to title, (url.nil? ? show_resource_path(resource) : url)}</p>" 
  end
  
  def list_item_simple_list items, attribute
    html = "<p class=\"list_item_attribute\"><b>#{(items.size > 1 ? attribute.pluralize : attribute)}:</b> "
    if items.empty?
      html << "<span class='none_text'>None specified</span>"
    else
      items.each do |i|
        if block_given?
          value = yield(i)
        else
          value = (link_to get_object_title(i), i)
        end
        html << value + (i == items.last ? "" : ", ")
      end
    end
    return html + "</p>"
  end  
  
  def list_item_authorized_list items, attribute, sort=true, max_length=75
    html = "<p class=\"list_item_attribute\"><b>#{(items.size > 1 ? attribute.pluralize : attribute)}:</b> "
    items = Authorization.authorize_collection("view", items, current_user,false)
    if items.empty?
      html << "<span class='none_text'>No #{attribute.downcase} or non visible to you</span>"
    else
      items = items.sort{|a,b| get_object_title(a)<=>get_object_title(b)} if sort
      items.each do |i|
        html << (link_to h(truncate(i.title,:length=>max_length)), i.class.name.include?("::Version") ? polymorphic_path(i.parent, :version => i.version) : i,:title=>get_object_title(i))
        html << ", " unless items.last==i
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
  
  def list_item_double_attribute attribute1, value1, url1, attribute2, value2, url2=nil
    unless url1.nil?
      value1 = link_to value1, url1
    end
    unless url2.nil?
      value2 = link_to value2, url2
    end
    return "<p class=\"list_item_attribute\"><b>#{attribute1}</b>: #{value1}<b style=\"margin-left:2em\">#{attribute2}</b>: #{value2}</p>"
  end
  
  def list_item_optional_attribute attribute, value, url=nil, missing_value_text="None specified"
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
  
end