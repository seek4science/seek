module AvatarsHelper
  
  def all_avatars_link(avatars_for_instance)
    eval("#{avatars_for_instance.class.name.downcase}_avatars_url(#{avatars_for_instance.id})")
  end
  
  def new_avatar_link(avatar_for_instance)
    eval("new_#{avatar_for_instance.class.name.downcase}_avatar_url(#{avatar_for_instance.id})")
  end

  # A generic key to produce avatars for entities of all kinds.
  #
  # Parameters:
  # 1) object - the instance of the object which requires the avatar;
  # 2) size - size of the square are, where the avatar will reside (the aspect ratio of the picture is preserved by ImageMagick);
  # 3) return_image_tag_only - produces only the <img /> tag; the picture won't be linked to anywhere; no 'alt' / 'title' attributes;
  # 4) url - when the avatar is clicked, this is the url to redirect to; by default - the url of the "object";
  # 5) alt - text to show as 'alt' / 'tooltip'; by default "name" attribute of the "object"; when empty string - nothing is shown;
  # 6) "show_tooltip" - when set to true, text in "alt" get shown as tooltip; otherwise put in "alt" attribute
  def avatar(object, size=200, return_image_tag_only=false, url=nil, alt=nil, show_tooltip=true)
    alternative = ""
    title = get_object_title(object)
    if show_tooltip
      tooltip_text = (alt.nil? ? h(title) : alt)
    else
      alternative = (alt.nil? ? h(title) : alt)
    end

    case object.class.name.downcase
      when "person", "institution", "project", "programme"
        if object.avatar_selected?
          img = image_tag avatar_url(object, object.avatar_id, size), :alt=> alternative, :class => 'framed'
        else
          img = default_avatar(object.class.name, size, alternative)
        end
      when "datafile", "sop"
        img = image_tag file_type_icon_url(object),
                        :alt => alt,
                        :class=> "avatar framed"
      when "model","investigation","study","publication"
        img = image "#{object.class.name.downcase}_avatar",
                    {:alt => alt,
                     :class=>"avatar framed"}
      when "assay"
        type=object.is_modelling? ? "modelling" : "experimental"
        img = image "#{object.class.name.downcase}_#{type}_avatar",
                    {:alt => alt,
                     :class=>"avatar framed"}
    end

    # if the image of the avatar needs to be linked not to the url of the object, return only the image tag
    if return_image_tag_only
      return img
    else
      unless url
        url = eval("#{object.class.name.downcase}_url(#{object.id})")
      end

      return link_to(img, url, :title => tooltip_title_attrib(tooltip_text))
    end
  end

  def avatar_url(avatar_for_instance, avatar_id, size=nil)
    serve_from_public = Rails.configuration.assets.enabled
    if serve_from_public
      avatar = Avatar.find(avatar_id)
      if avatar_for_instance.avatars.include?(avatar)
        avatar.public_asset_url(size)
      else
        raise "Avatar does not belong to instance"
      end
    else
      basic_url = eval("#{avatar_for_instance.class.name.downcase}_avatar_path(#{avatar_for_instance.id}, #{avatar_id})")
      append_size_parameter(basic_url,size)
    end
  end

  def default_avatar(object_class_name, size=200, alt="Anonymous", onclick_options="")
    avatar_filename=icon_filename_for_key("#{object_class_name.downcase}_avatar")

    image_tag avatar_filename,
              :alt => alt,
              :size => "#{size}x#{size}",
              :class => 'framed',
              :onclick => onclick_options
  end
  
end
