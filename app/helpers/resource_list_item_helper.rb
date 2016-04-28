module ResourceListItemHelper

  def get_list_item_content_partial resource
    get_original_model_name(resource).pluralize.underscore + "/resource_list_item"
  end

  def get_list_item_actions_partial resource
    if resource.authorization_supported? && resource.is_downloadable_asset?
      actions_partial = "assets/resource_actions_td"
    elsif resource.is_a?(Organism)
      actions_partial = "organisms/resource_actions_td"
    else
      actions_partial = nil
    end
    actions_partial
  end

  def get_list_item_avatar_partial resource
    if resource.show_contributor_avatars?
      "assets/asset_avatars"
    elsif resource.class.name.downcase=="event"
      ""
    else
      "avatars/list_item_avatars"
    end
  end

  def list_item_title resource, options={}
    cache_key = "rli_title_#{resource.cache_key}_#{resource.authorization_supported? && resource.can_manage?}"
    result = Rails.cache.fetch(cache_key) do
      title=options[:title]
      url=options[:url]
      include_avatar=options[:include_avatar]
      include_avatar=true if include_avatar.nil?

      if title.nil?
        title = get_object_title(resource)
      end

      html = "<div class=\"list_item_title\">"

      if resource.class.name.split("::")[0] == "Person"
        html = list_item_title_for_person(html, resource, title, url)
      else
        if include_avatar && (resource.avatar_key || resource.use_mime_type_for_avatar?)
          html = list_item_title_with_avatar(html, resource, title, url)
        else
          html << "#{link_to title, (url.nil? ? show_resource_path(resource) : url)}"
        end
      end
      html << "</div>"
    end
    visibility = resource.authorization_supported? && resource.can_manage? ? list_item_visibility(resource) : ""
    result = result.gsub("#item_visibility",visibility)
    result.html_safe
  end

  def list_item_title_for_person(html, person, title, url)
    icons = seek_role_icons(person, 16)
    html << "#{link_to title, (url.nil? ? show_resource_path(person) : url)} #{icons}"
    html
  end

  def list_item_title_with_avatar(html, resource, title, url)
    html << "#{favouritable_icon(resource, 24, :avatar_class => '')} #{link_to title, (url.nil? ? show_resource_path(resource) : url)}"
    html << "#item_visibility"
    html
  end

  def list_item_tag_list resource
    list_item_simple_list(resource.annotations.collect{|a| a.value}, "Tags") {|i| link_for_ann(i)}
  end

  def list_item_scale_list resource
    if resource.respond_to?(:scales)
      ordered_scales = sort_scales resource.scales
      list_item_simple_list(ordered_scales, "Scales") {|i| link_for_scale(i)}
    else
      nil
    end
  end

  def list_item_simple_list items, attribute
    html = "<p class=\"list_item_attribute\"><b>#{attribute}:</b> "
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
    html = html + "</p>"
    html.html_safe
  end

  def list_item_authorized_list *args
   "<p class=\"list_item_attribute\">#{authorized_list *args}</p>".html_safe
  end

  def list_item_attribute attribute, value, url=nil, url_options={}
    value = value.html_safe? ? value : h(value)
    unless url.nil?
      value = link_to value, url, url_options
    end
    html = "<p class=\"list_item_attribute\"><b>#{attribute}</b>: #{value}</p>"
    html.html_safe
  end

  def list_item_authorized_attribute attribute, object, url=nil, method = :title
    url = object if url.nil?
    not_authorized_text = object.try(:title_is_public?) ? h(object.title) : "Not available"
    list_item_optional_attribute attribute, object.try(:can_view?) ? object.send(method) : nil, url, not_authorized_text
  end

  def list_item_optional_attribute attribute, value, url=nil, missing_value_text="Not specified"
    if value.blank?
      value = "<span class='none_text'>#{missing_value_text}</span>"
    else
      value = value.html_safe? ? value : h(value)
      unless url.nil?
        value = link_to value, url
      end
    end
    html = missing_value_text.nil? ? "" : "<p class=\"list_item_attribute\"><b>#{attribute}</b>: #{value}</p>"
    html.html_safe
  end

  def list_item_timestamp resource
    html = "Created: " + date_as_string(resource.created_at,true)
    unless resource.created_at == resource.updated_at
      html << ", Last updated: " + date_as_string(resource.updated_at,true)
    end
    return html.html_safe
  end

  def list_profile_registered_timestamp resource
    html = "<p class=\"list_item_attribute none_text\" style=\"text-align:center;\"><b>Registered:</b> <label>" + (resource.try(:user).try(:created_at).nil? ? "Not yet registered" : date_as_string(resource.try(:user).try(:created_at)))
    html << "</label></p>"
    return html.html_safe
  end

  def list_item_description text, auto_link=true, length=500
    unless text.blank?
      html = "<div class='list_item_desc'>"
      html << text_or_not_specified(text, :description => true, :auto_link=>auto_link, :length=>length)
      html << "</div>"
      html.html_safe
    end
  end

  def small_list_item_description text, auto_link=true, length=150
    list_item_description text,auto_link,length
  end

  def list_item_contributor resource
    return "<p class=\"list_item_attribute\"><b>Uploader</b>: #{jerm_harvester_name}</p>".html_safe if resource.contributor.nil?
    list_item_authorized_attribute 'Uploader', resource.contributor.person
  end

  def list_item_expandable_text attribute, text, length=200
    full_text  = text_or_not_specified(text, :description => false, :auto_link=>false)
    trunc_text = text_or_not_specified(text, :description => false, :auto_link=>false, :length=>length)
    #Don't bother with fancy stuff if not enough text to expand
    if full_text == trunc_text
      html = (attribute ? "<p class=\"list_item_attribute\"><b>#{attribute}</b>:</p>" : "") + "<div class=\"list_item_desc\">"
      html << trunc_text
      html << "</div>"
      html.html_safe
    else
      html = "<script type=\"text/javascript\">\n"
      html << "fullResourceListItemExpandableText[#{text.object_id}] = '#{escape_javascript(full_text)}';\n"
      html << "truncResourceListItemExpandableText[#{text.object_id}]  = '#{escape_javascript(trunc_text)}';\n"
      html << "</script>\n"
      html << (attribute ? "<p class=\"list_item_attribute\"><b>#{attribute}</b> " : "")
      html << (link_to "(Expand)", "#", :id => "expandableLink#{text.object_id}", :onClick => "expandResourceListItemExpandableText(#{text.object_id});return false;")
      html << "</p>"
      html << "<div class=\"list_item_desc\"><div id=\"expandableText#{text.object_id}\">"
      html << trunc_text
      html << "</div>"
      html << "</div>"
      html.html_safe
    end
  end

  def list_item_visibility item,css_class="visibility_icon"
    title = ""
    html  = ""
    policy = item.policy

    case policy.sharing_scope
      when Policy::PRIVATE
        if policy.permissions.empty?
          title = "Private"
          html << image('lock', :title=>title, :class => css_class)
        else
          title = "Custom policy"
          html << image('manage', :title=>title, :class => css_class)
        end
      when Policy::ALL_USERS
        if policy.access_type > 0
          title = "Visible to all #{Seek::Config.project_name} #{t('project').pluralize}"
          html << image('open', :title=>title, :class => css_class)
        else
          title = "Visible to the #{t('project').pluralize.downcase} associated with this item"
          html << image('open', :title=>title, :class => css_class)
        end
      when Policy::EVERYONE
        if !item.is_downloadable? || (item.is_downloadable? && policy.access_type >= Policy::ACCESSIBLE)
          title = "Was published"
          html << image('world', :title=>title, :class => css_class)
        else
          title = "Visible to everyone, but not accessible"
          html << image('partial_world', :title=>title, :class => css_class)
        end
    end
    html << ""
    html.html_safe
  end

  def list_item_contributor_list(contributors, other_contributors = nil, key = 'Contributor')
    contributor_count = contributors.count
    contributor_count += 1 unless other_contributors.blank?
    html = ''
    other_html = ''
    content_tag(:p, :class => 'list_item_attribute') do
      html << content_tag(:b, "#{contributor_count == 1 ? key : key.pluralize}: ")
      html << contributors.map { |c| link_to truncate(c.title, :length => 75), show_resource_path(c), :title => get_object_title(c) }.join(', ')
      unless other_contributors.blank?
        other_html << ', ' unless contributors.empty?
        other_html << other_contributors
      end
      other_html << 'None' if contributor_count == 0
      html.html_safe + other_html
    end
  end

  def list_item_author_list(all_authors)
    authors = all_authors.select {|a| a.person && a.person.can_view? }
    other_authors = all_authors.select {|a| a.person.nil? }.map {|a| a.last_name + ' ' + a.first_name}.join(',')
    list_item_contributor_list(authors.map {|a| a.person}, other_authors, 'Author')
  end

end