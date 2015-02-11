module RelatedItemsHelper
  
  def prepare_resource_hash(resource_hash, authorization_already_done = false, limit = nil, show_empty_tabs = false, is_one_facet = false)
    perform_authorization(resource_hash) unless authorization_already_done
    limit_items(resource_hash, limit) unless limit.nil?
    remove_empty_tabs(resource_hash) unless show_empty_tabs
    sort_items(resource_hash, is_one_facet)
  end

  private

  def perform_authorization(resource_hash)
    resource_hash.each_value do |res|
      unless res[:items].empty?
        total_count = res[:items].size
        total = res[:items]
        res[:items] = res[:items].select &:can_view?
        res[:hidden_items] = total - res[:items]
        res[:hidden_count] = total_count - res[:items].size
      end
    end
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

  def sort_items(resource_hash, is_one_facet)
    ordered_keys = resource_hash.keys.sort_by do |asset|
      ASSET_ORDER.index(asset) || (resource_hash[asset][:is_external] ? 10000 : 1000)
    end

    ordered_keys.map {|key| resource_hash[key].merge(:type => key)}.each do |resource_type|
      resource_type[:hidden_count] ||= 0
      resource_type[:items] || []
      resource_type[:extra_count] ||= 0
      resource_type[:is_external] ||= false

      resource_type[:visible_resource_type] = internationalized_resource_name(resource_type[:type],!resource_type[:is_external] )
      resource_type[:tab_title] = "#{resource_type[:visible_resource_type]} "+
          "(#{(resource_type[:items].length+resource_type[:extra_count]).to_s}" +
          ((resource_type[:hidden_count]) > 0 ? "+#{resource_type[:hidden_count]}":"") + ")"

      resource_type[:tab_id] = resource_type[:type].downcase.pluralize.html_safe
      resource_type[:title_class] = resource_type[:is_external] ? "external_result" : ""

      resource_type[:total_visible] = resource_type[:items].count + resource_type[:extra_count]

      # Tweaks for resource_tabbed_one_facet partial
      if is_one_facet
        resource_type[:tab_id] = resource_type[:type]
        resource_type[:title_class] += " #{resource_type[:type]}" if is_one_facet
      end
    end
  end

  def remove_empty_tabs(resource_hash)
    resource_hash.each do |key, res|
      resource_hash.delete(key) if (res[:items].size + res[:hidden_count]) == 0
    end
  end
  
end
