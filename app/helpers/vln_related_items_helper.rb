module VlnRelatedItemsHelper
  # Resource hash for lazy loaded tabs, key: resource_type, value: resource
  # Each hash value
  def resource_hash_lazy_load(resource)
    resource_hash = {}
    all_related_items_hash = collect_related_items(resource)
    all_related_items_hash.each_key do |resource_type|
      all_related_items_hash[resource_type][:items] = all_related_items_hash[resource_type][:items].uniq.compact
      unless all_related_items_hash[resource_type][:items].empty?
        resource_hash[resource_type] = all_related_items_hash[resource_type][:items]
      end
    end
    resource_hash
  end

  def link_to_view_all_in_new_window(item, resource_type)
    path = item ? [item, resource_type.tableize] : eval("#{resource_type.pluralize.underscore}_path")
    link_text = item ? 'View all items with nested url in new window' : 'View all items in new window'
    link_to link_text, path, target: '_blank'
  end

  def link_to_view_all_related_items(item, resources, authorized_resources, scale_title)
    link = ''
    resource_type = resources.first.class.name
    count = authorized_resources.size
    tab_content_view_all = scale_title + '_' + resource_type + '_view_all'
    tab_content_view_some = scale_title + '_' + resource_type + '_view_some'
    ajax_link_to_view_in_current_window =
        link_to_with_callbacks "View all #{count} items here",
                               { url: url_for(action: 'related_items_tab_ajax'),
                                 method: 'get',
                                 condition: "check_tab_content('#{tab_content_view_all}', '#{tab_content_view_some}')",
                                 with: "'resource_type=' + '#{resource_type}'
                                          +  '&scale_title=' + '#{scale_title}'
                                          +  '&view_type=' + 'view_all'
                                          +  '#{item ? '&item_id=' + item.id.to_s + '&item_type=' + item.class.name : ''}'",
                                 before: "$('#{tab_content_view_some}').hide();
                                                   $('#{tab_content_view_all}').show();
                                                   show_large_ajax_loader('#{tab_content_view_all}');" },
                               remote: true

    link << ajax_link_to_view_in_current_window
    link << ' || '
    link << link_to_view_all_in_new_window(item, resource_type)
    link.html_safe
  end

  def ajax_link_to_view_limited_related_items(item, resources, scale_title, limit)
    resource_type = resources.first.class.name
    tab_content_view_all = scale_title + '_' + resource_type + '_view_all'
    tab_content_view_some = scale_title + '_' + resource_type + '_view_some'
    link =
        link_to_with_callbacks 'View only ' + limit.to_s + ' items',
                               { url: url_for(action: 'related_items_tab_ajax'),
                                 method: 'get',
                                 condition: "check_tab_content('#{tab_content_view_some}', '#{tab_content_view_all}')",
                                 with: "'resource_type=' + '#{resource_type}'
                                                                         +  '&scale_title=' + '#{scale_title}'
                                                                         +  '&view_type=' + 'view_some'
                                                                         +  '#{item ? '&item_id=' + item.id.to_s + '&item_type=' + item.class.name : ''}'",
                                 before: "$('#{tab_content_view_all}').hide();
                                               $('#{tab_content_view_some}').show();
                                               show_large_ajax_loader('#{tab_content_view_some}');" },
                               remote: true
    link.html_safe
  end
end
