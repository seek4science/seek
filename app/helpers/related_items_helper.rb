module RelatedItemsHelper

  def prepare_resource_hash(resource_hash, authorization_already_done = false, limit = nil, show_empty_tabs = false)
    perform_authorization(resource_hash) unless authorization_already_done
    limit_items(resource_hash, limit) unless limit.nil?
    remove_empty_tabs(resource_hash) unless show_empty_tabs
    sort_items(resource_hash)
  end

  private

  def perform_authorization(resource_hash)
    resource_hash.each_value do |resource_item|
      unless res[:items].empty?
        update_resource_items_for_authorization(resource_item)
      end
    end
  end

  def update_resource_items_for_authorization(resource_item)
    total_count = resource_item[:items].size
    total = resource_item[:items]
    resource_item[:items] = resource_item[:items].select &:can_view?
    resource_item[:hidden_items] = total - resource_item[:items]
    resource_item[:hidden_count] = total_count - resource_item[:items].size
  end

  def limit_items(resource_hash, limit)
    resource_hash.each_value do |res|
      if limit && res[:items].size > limit
        res[:extra_count] = res[:items].size - limit
        res[:extra_items] = res[:items][limit...(res[:items].size)]
        res[:items] = res[:items][0...limit]
      end
    end
  end

  def sort_items(resource_hash)
    ordered_keys(resource_hash).map { |key| resource_hash[key].merge(:type => key) }.each do |resource_type|
      update_resource_type(resource_type)
    end
  end

  def update_resource_type(resource_type)
    resource_type[:hidden_count] ||= 0
    resource_type[:items] || []
    resource_type[:extra_count] ||= 0
    resource_type[:is_external] ||= false

    resource_type[:visible_resource_type] = internationalized_resource_name(resource_type[:type], !resource_type[:is_external])
    resource_type[:tab_title] = resource_type_tab_title(resource_type)

    resource_type[:tab_id] = resource_type[:type].downcase.pluralize.gsub(" ","-").html_safe
    resource_type[:title_class] = resource_type[:is_external] ? "external_result" : ""
    resource_type[:total_visible] = resource_type_total_visible_count(resource_type)
  end

  def resource_type_total_visible_count(resource_type)
    resource_type[:items].count + resource_type[:extra_count]
  end

  def resource_type_tab_title(resource_type)
    "#{resource_type[:visible_resource_type]} "+
        "(#{(resource_type[:items].length+resource_type[:extra_count]).to_s}" +
        ((resource_type[:hidden_count]) > 0 ? "+#{resource_type[:hidden_count]}" : "") + ")"
  end

  def ordered_keys(resource_hash)
    resource_hash.keys.sort_by do |asset|
      ASSET_ORDER.index(asset) || (resource_hash[asset][:is_external] ? 10000 : 1000)
    end
  end

  def remove_empty_tabs(resource_hash)
    resource_hash.each do |key, res|
      resource_hash.delete(key) if (res[:items].size + res[:hidden_count]) == 0
    end
  end

end
