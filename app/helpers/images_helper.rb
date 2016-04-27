# To change this template, choose Tools | Templates
# and open the template in the editor.

module ImagesHelper

  include Seek::MimeTypes
  
  def info_icon_with_tooltip(info_text)
    return image("info",
      'data-tooltip' => tooltip(info_text),
      :style => "vertical-align:middle;")
  end

  #mirrors image_tag but uses a key instead of a source
  def simple_image_tag_for_key key, options={}
    return nil unless (filename = icon_filename_for_key(key.downcase))
    image_tag filename,options
  end

  def image_tag_for_key(key, url=nil, alt=nil, html_options={}, label=key.humanize, remote=false, size=nil)

    label = 'Delete' if label == 'Destroy'
    
    return nil unless (filename = icon_filename_for_key(key.downcase))

    image_options = alt ? { :alt => alt } : { :alt => key.humanize }
    image_options[:size] = "#{size}x#{size}" unless size.blank?
    img_tag = image_tag(filename, image_options).html_safe

    inner = img_tag.html_safe;
    inner = "#{img_tag} #{label}".html_safe unless label.blank?

    if (url)
      if (remote==:function)
        inner = link_to_function inner, url, html_options
      elsif (remote)
        inner = link_to(inner, url, html_options.merge(:remote => true))
      else
        inner = link_to(inner, url, html_options)
      end
    end
    
    inner.html_safe
  end

  def resource_avatar resource,html_options={}

    if resource.avatar_key
          image_tag(icon_filename_for_key(resource.avatar_key), html_options)
    elsif resource.use_mime_type_for_avatar?
          image_tag(file_type_icon_url(resource), html_options)
    end
  end
  
  def icon_filename_for_key(key)
    (@@icon_dictionary ||= Seek::ImageFileDictionary.instance).image_filename_for_key(key)
  end

  def image key,options={}
    image_tag(icon_filename_for_key(key),options)
  end
  
  def help_icon(text, delay=200, extra_style="")
    image("info", :alt=>"help", 'data-tooltip' => tooltip(text), :style => "vertical-align: middle;#{extra_style}")
  end
  
  def flag_icon(country, text=country, margin_right='0.3em')
    return '' unless country && !country.empty?

    code = country_code(country)
    
    if code && !code.empty?
      image_tag("famfamfam_flags/#{code.downcase}.png",
        'data-tooltip' => tooltip(text),
        :style => "vertical-align:middle; margin-right: #{margin_right};")
    else
      ''
    end
  end

  def model_image_url(model_instance, model_image_id, size=nil)
    basic_url = eval("model_model_image_path(#{model_instance.id}, #{model_image_id})")

    basic_url = append_size_parameter(basic_url,size)

    return basic_url
  end

  def append_size_parameter url,size
    if size
      url << "?size=#{size}"
      url << "x#{size}" if size.kind_of?(Numeric)
    end
    url
  end

  def delete_icon model_item, user
    item_name = text_for_resource model_item
    if model_item.can_delete?(user)
      html = content_tag(:li) { image_tag_for_key('destroy',url_for(model_item),"Delete #{item_name.downcase}", {:confirm=>"Are you sure?",:method=>:delete },"Delete #{item_name.downcase}") }
      return html.html_safe
    elsif model_item.can_manage?(user)
      explanation=unable_to_delete_text model_item
      html = "<li><span class='disabled_icon disabled' onclick='javascript:alert(\"#{explanation}\")' data-tooltip='#{tooltip(explanation)}' >"+image('destroy', {:alt=>"Delete",:class=>"disabled"}) + " Delete #{item_name} </span></li>"
      return html.html_safe
    end
  end

  def share_icon
    icon = simple_image_tag_for_key('share').html_safe
    html = link_to_remote_redbox(icon + "Share workflow".html_safe,
                                 {:url => url_for(:action => 'temp_link'),
                                  :failure => "alert('Sorry, an error has occurred.'); RedBox.close();"}
    )
    return html.html_safe
  end

  def file_type_icon(item)
    url = file_type_icon_url(item)
    image_tag url, :class => "icon"
  end

  def file_type_icon_key(item)
    mime_icon_key item.content_blob.try :content_type
  end

  def file_type_icon_url(item)
    mime_icon_url item.content_blob.try :content_type
  end
  
  def expand_image(margin_left="0.3em")
    toggle_image(margin_left,"expand")
  end
  
  def collapse_image(margin_left="0.3em")
    toggle_image(margin_left,"collapse")
  end

  def toggle_image(margin_left,key)
    image_tag icon_filename_for_key(key), :style => "margin-left: #{margin_left}; vertical-align: middle;", :alt => key, 'data-tooltip' => tooltip("#{key.capitalize} for more details")
  end

  def expand_plus_image(size="18x18")
    image_tag icon_filename_for_key("expand_plus"),:size=>size,:alt => 'Expand', 'data-tooltip' => tooltip("Expand for more details")
  end

  def collapse_minus_image(size="18x18")
    image_tag icon_filename_for_key("collapse_minus"),:size=>size,:alt => 'Collapse', 'data-tooltip' => tooltip("Collapse the details")
  end

  def header_logo_image
    if Seek::Config.header_image_avatar_id && avatar=Avatar.find_by_id(Seek::Config.header_image_avatar_id)
      image_tag(avatar.public_asset_url)
    else
      image('header_image_default')
    end
  end


  
end
