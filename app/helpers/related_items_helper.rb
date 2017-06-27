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
    resource_item[:items] = resource_item[:items].select(&:can_view?)
    resource_item[:hidden_items] = total - resource_item[:items]
    resource_item[:hidden_count] = total_count - resource_item[:items].size
  end

  def limit_items(resource_hash, limit)
    resource_hash.each_value do |res|
      next unless limit && res[:items].size > limit
      res[:extra_count] = res[:items].size - limit
      res[:extra_items] = res[:items][limit...(res[:items].size)]
      res[:items] = res[:items][0...limit]
    end
  end

  def sort_items(resource_hash)
    ordered_keys(resource_hash).map { |key| resource_hash[key].merge(type: key) }.each do |resource_type|
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

    resource_type[:tab_id] = resource_type[:type].downcase.pluralize.tr(' ', '-').html_safe
    resource_type[:title_class] = resource_type[:is_external] ? 'external_result' : ''
    resource_type[:total_visible] = resource_type_total_visible_count(resource_type)
  end

  def resource_type_total_visible_count(resource_type)
    resource_type[:items].count + resource_type[:extra_count]
  end

  def resource_type_tab_title(resource_type)
    "#{resource_type[:visible_resource_type]} "\
        "(#{(resource_type[:items].length + resource_type[:extra_count])}" +
      ((resource_type[:hidden_count]) > 0 ? "+#{resource_type[:hidden_count]}" : '') + ')'
  end

  def ordered_keys(resource_hash)
    resource_hash.keys.sort_by do |asset|
      ASSET_ORDER.index(asset) || (resource_hash[asset][:is_external] ? 10_000 : 1000)
    end
  end

  def remove_empty_tabs(resource_hash)
    resource_hash.each do |key, res|
      resource_hash.delete(key) if (res[:items].size + res[:hidden_count]) == 0
    end
  end

  # Get a hash of appropriate related resources for the given resource. Also returns a hash of hidden resources
  def get_related_resources(resource, limit = nil)
    return resource_hash_lazy_load(resource) if Seek::Config.tabs_lazy_load_enabled

    related = collect_related_items(resource)

    # Authorize
    authorize_related_items(related)

    order_related_items(related)

    # Limit items viewable, and put the excess count in extra_count
    related.each_key do |key|
      if limit && related[key][:items].size > limit && %w(Project Investigation Study Assay Person Specimen Sample Run Workflow Sweep).include?(resource.class.name)
        related[key][:extra_count] = related[key][:items].size - limit
        related[key][:items] = related[key][:items][0...limit]
      end
    end

    related
  end

  def relatable_types
    { 'Person' => {}, 'Project' => {}, 'Institution' => {}, 'Investigation' => {},
      'Study' => {}, 'Assay' => {}, 'DataFile' => {}, 'Model' => {}, 'Sop' => {}, 'Publication' => {}, 'Presentation' => {}, 'Event' => {},
      'Workflow' => {}, 'TavernaPlayer::Run' => {}, 'Sweep' => {}, 'Strain' => {}, 'Sample' => {}
    }
  end

  def related_items_method(resource, item_type)
    if item_type == 'TavernaPlayer::Run'
      method_name = 'runs'
    else
      method_name = item_type.underscore.pluralize
    end

    if resource.respond_to? "related_#{method_name}"
      resource.send "related_#{method_name}"
    elsif resource.respond_to? "related_#{method_name.singularize}"
      Array(resource.send("related_#{method_name.singularize}"))
    elsif resource.respond_to? method_name
      resource.send method_name
    elsif item_type != 'Person' && resource.respond_to?(method_name.singularize) # check is to avoid Person.person
      Array(resource.send(method_name.singularize))
    else
      []
    end
  end

  def order_related_items(related)
    related.each do |_key, res|
      res[:items].sort! { |item, item2| item2.updated_at <=> item.updated_at }
    end
  end

  def authorize_related_items(related)
    related.each do |key, res|
      res[:items] = res[:items].uniq.compact
      next if res[:items].empty?
      total_count = res[:items].size
      if key == 'Project' || key == 'Institution'
        res[:hidden_count] = 0
      elsif key == 'Person'
        if Seek::Config.is_virtualliver && User.current_user.nil?
          res[:items] = []
          res[:hidden_count] = total_count
        else
          res[:hidden_count] = 0
        end
      else
        total = res[:items]
        res[:items] = key.constantize.authorize_asset_collection res[:items], 'view', User.current_user
        res[:hidden_count] = total_count - res[:items].size
        res[:hidden_items] = total - res[:items]
      end
    end
  end

  def collect_related_items(resource)
    related = relatable_types
    related.delete('Person') if resource.class == 'Person' # to avoid the same person showing up

    related.each_key do |type|
      related[type][:items] = related_items_method(resource, type)
      related[type][:hidden_items] = []
      related[type][:hidden_count] = 0
      related[type][:extra_count] = 0
    end

    related
  end
end
