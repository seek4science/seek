# To change this template, choose Tools | Templates
# and open the template in the editor.

module ImagesHelper
  include Seek::MimeTypes

  def image_tag_for_key(key, url = nil, alt = nil, html_options = {}, label = key.humanize, remote = false, size = nil)
    label = 'Delete' if label == 'Destroy'
    return nil unless (filename = icon_filename_for_key(key.downcase))

    image_options = alt ? { alt: alt } : { alt: key.humanize }
    image_options[:size] = "#{size}x#{size}" unless size.blank?
    img_tag = image_tag(filename, image_options).html_safe

    inner = img_tag.html_safe
    inner = "#{img_tag} #{label}".html_safe unless label.blank?

    if url
      inner = if remote
                link_to(inner, url, html_options.merge(remote: true))
              else
                link_to(inner, url, html_options)
              end
    end

    inner.html_safe
  end

  def resource_avatar(resource, html_options = {})
    image_tag(resource_avatar_path(resource), html_options)
  end

  def resource_avatar_path(resource)
    if resource.avatar_key
      icon_filename_for_key(resource.avatar_key)
    elsif resource.use_mime_type_for_avatar?
      file_type_icon_url(resource)
    end
  end

  def icon_filename_for_key(key)
    Seek::ImageFileDictionary.instance.image_filename_for_key(key)
  end

  def image(key, options = {})
    filename = icon_filename_for_key(key)
    raise "Image not found for key: #{key}" if filename.nil? && !Rails.env.production?
    image_tag(filename, options)
  end

  def flag_icon(country, text = country, margin_right = '0.3em')
    return '' unless country && !country.empty?

    code = country_code(country)

    if code.present? && CountryCodes.has_flag?(code)
      image_tag("famfamfam_flags/#{code.downcase}.png",
                'data-tooltip' => tooltip(text),
                :style => "vertical-align:middle; margin-right: #{margin_right};")
    else
      ''
    end
  end

  def append_size_parameter(url, size)
    if size
      url << "?size=#{size}"
      url << "x#{size}" if size.is_a?(Numeric)
    end
    url
  end

  def delete_icon(model_item, user, confirm_msg='Are you sure?', alternative_item_name=nil)
    item_name = alternative_item_name.nil? ? (text_for_resource model_item) : alternative_item_name
    if model_item.can_delete?(user)
      fullURL = url_for(model_item)

      ## Add return path if available
      fullURL = polymorphic_url(model_item,:return_to=>URI(request.referer).path) if request.referer

      html = content_tag(:li) do
        image_tag_for_key('destroy', fullURL, "Delete #{item_name}", { data: { confirm: confirm_msg }, method: :delete}, "Delete #{item_name}")
      end
      html.html_safe
    elsif model_item.can_manage?(user)
      explanation = unable_to_delete_text model_item
      html = "<li><span class='disabled_icon disabled' onclick='javascript:alert(\"#{explanation}\")' data-tooltip='#{tooltip(explanation)}' >" + image('destroy', alt: 'Delete', class: 'disabled') + " Delete #{item_name} </span></li>"
      html.html_safe
    end
  end

 def order_icon(model_item, user, full_url, subitems, subitem_name)
   subitem_name = "#{t(subitem_name).capitalize.pluralize}"
   item_name = text_for_resource model_item
   explanation = ""
   if !model_item.can_edit?(user)
     explanation = "You cannot edit this #{item_name}"
   elsif subitems.size < 2
     explanation = "The #{item_name} must contain two or more #{subitem_name.pluralize}"
   end

   if !explanation.empty?
            html = "<li><span class='disabled_icon disabled' onclick='javascript:alert(\"#{explanation}\")' data-tooltip='#{tooltip(explanation)}' >" + image('order', alt: 'Order', class: 'disabled') + " Order #{subitem_name} </span></li>"
      return html.html_safe
   end

   html = content_tag(:li) do
     image_tag_for_key('order', full_url, "Order #{subitem_name.pluralize}", nil, "Order #{subitem_name.pluralize}")
     end
   html.html_safe
 end

 def file_type_icon(item)
    url = file_type_icon_url(item)
    image_tag url, class: 'icon'
  end

  def file_type_icon_url(item)
    mime_icon_url item.content_blob.try :content_type
  end

  def expand_image(margin_left = '0.3em')
    toggle_image(margin_left, 'expand')
  end

  def collapse_image(margin_left = '0.3em')
    toggle_image(margin_left, 'collapse')
  end

  def toggle_image(margin_left, key)
    image_tag icon_filename_for_key(key), :style => "margin-left: #{margin_left}; vertical-align: middle;", :alt => key, 'data-tooltip' => tooltip("#{key.capitalize} for more details")
  end

  def expand_plus_image(size = '18x18')
    image_tag icon_filename_for_key('expand_plus'), :size => size, :alt => 'Expand', 'data-tooltip' => tooltip('Expand for more details')
  end

  def collapse_minus_image(size = '18x18')
    image_tag icon_filename_for_key('collapse_minus'), :size => size, :alt => 'Collapse', 'data-tooltip' => tooltip('Collapse the details')
  end

  def header_logo_image
    if Seek::Config.header_image_avatar_id && avatar = Avatar.find_by_id(Seek::Config.header_image_avatar_id)
      image_tag(avatar.public_asset_url, options={:style=>'background-color:white', alt:Seek::Config.header_image_title })
    else
      image('header_image_default')
    end
  end
end
