module VlnRelatedItemsHelper
  # Resource hash for lazy loaded tabs, key: resource_type, value: resource
  # Each hash value
  def resource_hash_lazy_load(resource)
    resource_hash = {}
    all_related_items_hash = get_related_resources(resource)
    all_related_items_hash.each_key do |resource_type|
      all_related_items_hash[resource_type][:items] = all_related_items_hash[resource_type][:items].uniq.compact
      unless all_related_items_hash[resource_type][:items].empty?
        resource_hash[resource_type] = all_related_items_hash[resource_type][:items]
      end
    end
    resource_hash
  end
end
