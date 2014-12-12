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
  def avatar(object, size = 200, return_image_tag_only = false, url = nil, alt = nil, show_tooltip = true)
    title = get_object_title(object)

    alternative, tooltip_text = avatar_alternative_and_tooltip_text(alt, show_tooltip, title)

    img = avatar_image_tag_for_item(object, alternative, size, alt)

    # if the image of the avatar needs to be linked not to the url of the object, return only the image tag
    if return_image_tag_only
      img
    else
      url ||= eval("#{object.class.name.downcase}_url(#{object.id})")
      link_to(img, url, title: tooltip_title_attrib(tooltip_text))
    end
  end

  def avatar_image_tag_for_item(item, alternative, size, alt)
    case item.class.name.downcase
      when 'person', 'institution', 'project', 'programme'
        avatar_according_to_user_upload(alternative, item, size)
      when 'datafile', 'sop'
        avatar_according_to_item_mime_type(item, alt)
      when 'model', 'investigation', 'study', 'publication', 'assay'
        avatar_according_to_item_type(item, alt)
    end
  end

  def avatar_according_to_item_type(item, alt)
    if item.is_a?(Assay)
      key = item.is_modelling? ? 'modelling' : 'experimental'
      key = "#{item.class.name.downcase}_#{key}_avatar"
    else
      key = "#{item.class.name.downcase}_avatar"
    end
    image key, alt: alt, class: 'avatar framed'
  end

  def avatar_according_to_item_mime_type(item, alt)
    image_tag file_type_icon_url(item),
              alt: alt,
              class: 'avatar framed'
  end

  def avatar_according_to_user_upload(alternative, item, size)
    if item.avatar_selected?
      image_tag avatar_url(item, item.avatar_id, size), alt: alternative, class: 'framed'
    else
      default_avatar(item.class.name, size, alternative)
    end
  end

  def avatar_alternative_and_tooltip_text(alt, show_tooltip, title)
    alternative = ''
    if show_tooltip
      tooltip_text = (alt.nil? ? h(title) : alt)
    else
      alternative = (alt.nil? ? h(title) : alt)
    end
    [alternative, tooltip_text]
  end

  def avatar_url(avatar_for_instance, avatar_id, size = nil)
    serve_from_public = Rails.configuration.assets.enabled
    if serve_from_public
      avatar = Avatar.find(avatar_id)
      if avatar_for_instance.avatars.include?(avatar)
        avatar.public_asset_url(size)
      else
        fail 'Avatar does not belong to instance'
      end
    else
      basic_url = eval("#{avatar_for_instance.class.name.downcase}_avatar_path(#{avatar_for_instance.id}, #{avatar_id})")
      append_size_parameter(basic_url, size)
    end
  end

  def default_avatar(object_class_name, size = 200, alt = 'Anonymous', onclick_options = '')
    avatar_filename = icon_filename_for_key("#{object_class_name.downcase}_avatar")

    image_tag avatar_filename,
              alt: alt,
              size: "#{size}x#{size}",
              class: 'framed',
              onclick: onclick_options
  end
end
