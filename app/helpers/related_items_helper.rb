module RelatedItemsHelper
  def prepare_resource_hash(resource_hash, authorization_already_done = false, limit = nil, show_empty_tabs = false)
    perform_authorization(resource_hash) unless authorization_already_done
    limit_items(resource_hash, limit) unless limit.nil?
    remove_empty_tabs(resource_hash) unless show_empty_tabs
    update_item_details(resource_hash)
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

    related = relatable_types
    related.delete('Person') if resource.is_a?(Person) # to avoid the same person showing up
    related.delete('Organism') unless resource.is_a?(Sample)

    related.each_key do |type|
      method = related_items_method_name(resource, type)
      related[type][:items] = method ? resource.send(method) : []
      total_count = related[type][:items].respond_to?(:count) ? related[type][:items].count : 1
      related[type][:hidden_items] = []
      related[type][:hidden_count] = 0
      related[type][:extra_count] = 0
      related[type][:items] = [related[type][:items]].compact unless related[type][:items].is_a?(Enumerable)

      if related[type][:items].any?
        if type == 'Project' || type == 'Institution' || type == 'SampleType'
          related[type][:hidden_count] = 0
        elsif (type == 'Workflow' || type == 'Node') && !Seek::Config.workflows_enabled
          related[type][:items] = []
          related[type][:hidden_count] = 0
        elsif type == 'Person'
          if Seek::Config.is_virtualliver && User.current_user.nil?
            related[type][:items] = []
            related[type][:hidden_count] = total_count
          else
            related[type][:hidden_count] = 0
          end
        elsif type.constantize.respond_to?(:all_authorized_for)
          total = related[type][:items]
          related[type][:items] = related[type][:items].all_authorized_for('view', User.current_user)
          related[type][:hidden_count] = total_count - related[type][:items].count
          related[type][:hidden_items] = total - related[type][:items]
        end

        related[type][:items] = Seek::ListSorter.sort_by_order(related[type][:items], Seek::ListSorter.order_for_view(type, :related))

        if limit && related[type][:items].size > limit && %w[Project Investigation Study Assay Person Specimen Sample Snapshot].include?(resource.class.name)
          related[type][:extra_count] = related[type][:count] - limit
          related[type][:items] = related[type][:items].first(limit)
        end
      end
    end

    related
  end

  def relatable_types
    { 'Person' => {}, 'Project' => {}, 'Institution' => {}, 'Investigation' => {},
      'Study' => {}, 'Assay' => {}, 'DataFile' => {}, 'Document' => {},
      'Model' => {}, 'Sop' => {}, 'Publication' => {}, 'Presentation' => {}, 'Event' => {}, 'Organism' => {},
      'Strain' => {}, 'Sample' => {}, 'Workflow' => {}, 'Node' => {} }
  end

  def related_items_method_name(resource, item_type)
    method_name = item_type.underscore.pluralize

    if resource.respond_to?("related_#{method_name}")
      "related_#{method_name}"
    elsif resource.respond_to? "related_#{method_name.singularize}"
      "related_#{method_name.singularize}"
    elsif resource.respond_to?(method_name)
      method_name
    elsif item_type != 'Person' && resource.respond_to?(method_name.singularize) # check is to avoid Person.person
      method_name.singularize
    end
  end

  def self.relations_methods
    resource_klass = self.class
    method_hash = {}
    relatable_types.each_key do |item_type|
      method_name = item_type.underscore.pluralize

      if resource_klass.method_defined? "related_#{method_name}"
        method_hash[item_type] = "related_#{method_name}"
      elsif resource.respond_to? "related_#{method_name.singularize}"
        method_hash[item_type] = "related_#{method_name.singularize}"
      elsif resource.respond_to? method_name
        method_hash[item_type] = method_name
      elsif item_type != 'Person' && resource.respond_to?(method_name.singularize) # check is to avoid Person.person
        method_hash[item_type] = method_name
      else
        []
      end
    end
    method_hash
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
