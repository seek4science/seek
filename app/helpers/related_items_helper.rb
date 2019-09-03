module RelatedItemsHelper
  def prepare_resource_hash(resource_hash)
    update_item_details(resource_hash)
  end

  private

  def update_item_details(resource_hash)
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
    resource_type[:items_count] + resource_type[:extra_count]
  end

  def resource_type_tab_title(resource_type)
    "#{resource_type[:visible_resource_type]} "\
        "(#{(resource_type_total_visible_count(resource_type))}" +
      ((resource_type[:hidden_count]) > 0 ? "+#{resource_type[:hidden_count]}" : '') + ')'
  end

  def ordered_keys(resource_hash)
    resource_hash.keys.sort_by do |asset|
      ASSET_ORDER.index(asset) || (resource_hash[asset][:is_external] ? 10_000 : 1000)
    end
  end

  def remove_empty_tabs(resource_hash)
    resource_hash.each do |key, res|
      resource_hash.delete(key) if (res[:items_count] + res[:hidden_count]) == 0
    end
  end

  # Get a hash of appropriate related resources for the given resource. Also returns a hash of hidden resources
  def get_related_resources(resource, limit = nil)
    return resource_hash_lazy_load(resource) if Seek::Config.tabs_lazy_load_enabled

    hash = {}
    resource.class.related_types.each do |type|
      next if type == 'Person' && resource.is_a?(Person) # to avoid the same person showing up
      next if type == 'Organism' && !resource.is_a?(Sample)
      next if type == 'Workflow' || type == 'Node' && !Seek::Config.workflows_enabled

      hash[type] = {}

      items = resource.get_related(type)
      items = [] if items.nil?
      items = [items] if items.is_a?(ApplicationRecord)

      hash[type][:items] = items
      hash[type][:items_count] = hash[type][:items].count
      hash[type][:hidden_items] = []
      hash[type][:hidden_count] = 0
      hash[type][:extra_count] = 0

      if hash[type][:items].any?
        total = hash[type][:items].to_a
        total_count = hash[type][:items_count]
        hash[type][:items] = hash[type][:items].all_authorized_for('view', User.current_user).to_a
        hash[type][:items_count] = hash[type][:items].count
        hash[type][:hidden_count] = total_count - hash[type][:items_count]
        hash[type][:hidden_items] = total - hash[type][:items]

        hash[type][:items] = Seek::ListSorter.sort_by_order(hash[type][:items], Seek::ListSorter.order_for_view(type, :related))

        if limit && hash[type][:items_count] > limit
          hash[type][:items] = hash[type][:items].first(limit)
          hash[type][:extra_count] = hash[type][:items_count] - limit
          hash[type][:items_count] = limit
        end
      end
    end

    hash
  end

  def sort_project_member_by_status(resource, project_id)
    project = Project.find(project_id)
    resource.sort_by { |person| person.current_projects.include?(project) ? 0 : 1 }
  end

  def get_person_id
    if !params[:id].nil?
      person_id = params[:id]
    elsif !params[:person_id].nil?
      person_id = params[:person_id]
    end
    person_id
  end
end
