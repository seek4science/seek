module AvatarsHelper
  # A generic key to produce avatars for entities of all kinds.
  #
  # Parameters:
  # 1) object - the instance of the object which requires the avatar;
  # 2) size - size of the square are, where the avatar will reside (the aspect ratio of the picture is preserved by ImageMagick);
  # 3) return_image_tag_only - produces only the <img /> tag; the picture won't be linked to anywhere; no 'alt' / 'title' attributes;
  # 4) url - when the avatar is clicked, this is the url to redirect to; by default - the url of the "object";
  # 5) alt - text to show as 'alt' / 'tooltip'; by default "name" attribute of the "object"; when empty string - nothing is shown;
  # 6) "show_tooltip" - when set to true, text in "alt" get shown as tooltip; otherwise put in "alt" attribute
  def avatar(object, size = 200, return_image_tag_only = false, url = nil, alt = nil, show_tooltip = true, css_class = 'framed')
    title = get_object_title(object)

    alternative, tooltip_text = avatar_alternative_and_tooltip_text(alt, show_tooltip, title)

    img = avatar_image_tag_for_item(object, alternative, size, alt, css_class)

    # if the image of the avatar needs to be linked not to the url of the object, return only the image tag
    if return_image_tag_only
      img
    else
      url ||= polymorphic_url(object)
      link_to(img, url, 'data-tooltip' => tooltip(tooltip_text))
    end
  end

  def avatar_image_tag_for_item(item, alternative, size, alt, css_class = 'framed')
    if item.defines_own_avatar?
      avatar_according_to_user_upload(alternative, item, size, css_class)
    else
      resource_avatar(item, alt: alt, class: css_class)
    end
  end

  def avatar_according_to_user_upload(alternative, item, size, css_class = 'framed')
    if item.avatar_selected?
      image_tag avatar_url(item, item.avatar, size), alt: alternative, class: css_class
    else
      default_avatar(item.class.name, size, alternative, '', css_class)
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

  def avatar_url(owner, avatar, size = nil)
    #serve_from_public = Rails.configuration.assets.enabled
    if Rails.env.production?
      if owner.avatars.include?(avatar)
        avatar.public_asset_url(size)
      else
        raise 'Avatar does not belong to instance'
      end
    else
      basic_url = polymorphic_path([owner, avatar])
      append_size_parameter(basic_url, size)
    end
  end

  def default_avatar(object_class_name, size = 200, alt = 'Anonymous', onclick_options = '', css_class = 'framed')
    avatar_filename = icon_filename_for_key("#{object_class_name.downcase}_avatar")

    image_tag avatar_filename,
              alt: alt,
              height: size,
              'max-width': size,
              class: css_class,
              onclick: onclick_options
  end

  def the_jerm_contributor_contributor_icon(options = {size: 50 })
    contributor_icon('jerm_logo','jerm_harvester_name',options)
  end

  def deleted_contributor_contributor_icon(options = {size: 50 })
    contributor_icon('deleted_contributor_icon','deleted_contributor_name',options)
  end

  def contributor_icon icon_key, text_key, options
    logo_filename = icon_filename_for_key(icon_key)
    size = options[:size]
    image_tag logo_filename,
              alt: t(text_key),
              size: "#{size}x#{size}",
              class: 'framed',
              style: 'padding: 2px;',
              title: t(text_key)
  end
end
