module FacetedBrowsingHelper
  def exhibit_trees facet_config
    exhibit_items = []
    facet_config.each do |key,value|
      facet_class = value['facet_class']
      if facet_class == 'Exhibit.HierarchicalFacet'
        tree_from = value['tree_from']
        tree_from.split(',').each do |tree_class|
          exhibit_items |= exhibit_tree(tree_class, key)
        end
      end
    end
    exhibit_items
  end

  def exhibit_tree tree_class, facet
    tree = []
    class_hierarchy = tree_class.constantize.instance.class_hierarchy
    tree.push({'type' => facet, 'label' => h(class_hierarchy.label)})
    tree |=  generate_tree(class_hierarchy, facet)
    tree
  end

  def generate_tree parent_class, facet
    result = []
    parent_class.subclasses.each do |child|
      result << {'type' => facet, 'label' => h(child.label), 'subclassOf' => h(child.parents.first.label)}
      result = result + generate_tree(child, facet) unless child.subclasses.empty?
    end
    result
  end

  def exhibit_item_for object, facets_for_object
    exhibit_item = {}
    object_type = object.class.name
    object_id = object.id

    exhibit_item.merge!(exhibit_item_general_part(object_type, object_id))

    #generate facet values for each facet based on the config file
    facets_for_object.each do |key, value|
      #special case when generating project filter for project itself from common_faceted_search.yml
      if object.kind_of?(Project) && key == 'project'
        exhibit_item[key] = object.title
      elsif object.kind_of?(Person) && key == 'contributor'
        exhibit_item[key] = object.name
      elsif object.kind_of?(Assay) && object.assay_class.title == 'Modelling Analysis' && key == 'technology_type'
        exhibit_item[key] = "(don't have this field)"
      else
        exhibit_item[key] = value_for_key value, object
      end
    end
    exhibit_item
  end

  def exhibit_item_for_external_resource object, facets_for_object
    exhibit_item = {}
    object_type = object.tab
    object_id = object.id

    exhibit_item.merge!(exhibit_item_general_part(object_type, object_id))

    #generate facet values for each facet based on the config file
    facets_for_object.each do |key, value|
      exhibit_item[key] = value_for_key value, object
    end
    exhibit_item
  end

  def exhibit_item_general_part object_type, object_id
    exhibit_item = {}
    #this is to avoid exhibit warning messages
    exhibit_item['id'] = "#{object_type}#{object_id}"
    exhibit_item['label'] = "#{object_type}#{object_id}"

    #This display_content will be later on replaced by resource_list_item, by using ajax, otherwise it causes speed problem
    exhibit_item['display_content'] = ''

    exhibit_item['type'] = object_type
    exhibit_item['item_id'] = object_id
    exhibit_item
  end

  # generate value for each facet of each object based on configuration file
  # e.g. the configuration for project facet of DataFile is:
  # DataFile:
  #    project:
  #     label: Project
  #     value_from: projects:title
  # then the value generated is: data_file.projects.collect(&:title)

  def value_for_key config_for_key, object
    facet_values = []
    value_from = config_for_key['value_from']
    value_from.split(',').each do |from|
      facet_value = object
      from.split(':').each do |field|
        if facet_value.blank?
          break
        elsif facet_value.kind_of?(Array) and facet_value.first.respond_to?field
          facet_value = facet_value.collect(&:"#{field}")
        elsif facet_value.respond_to?field
          facet_value = facet_value.send(field)
        else
          facet_value = nil
        end
      end
      if facet_value.kind_of?(Array)
        facet_values |= facet_value
      else
        facet_values << facet_value
      end
    end
    facet_values.compact!
    facet_values.uniq!
    facet_values = '(Missing value)' if facet_values.blank?

    facet_values
  end

  def faceted_browsing_config_path
    File.join(Rails.root, "config/facet", "faceted_browsing.yml")
  end

  def common_faceted_search_config_path
    File.join(Rails.root, "config/facet", "common_faceted_search.yml")
  end

  def specified_faceted_search_config_path
    File.join(Rails.root, "config/facet", "specified_faceted_search.yml")
  end

  def external_faceted_search_config_path
    File.join(Rails.root, "config/facet", "external_faceted_search.yml")
  end

  def index_with_facets? controller_name
    Seek::Config.faceted_browsing_enabled && Seek::Config.facet_enable_for_pages[controller_name] && ie_support_faceted_browsing?
  end

  def ie_support_faceted_browsing?
    ie_support_faceted_browsing = true
    user_agent = request.env["HTTP_USER_AGENT"]
    index = user_agent.try(:index, 'MSIE')
    if !index.nil?
      version = user_agent[(index+5)..(index+8)].to_i
      if version != 0 && version < 9
        ie_support_faceted_browsing = false
      end
    end
    ie_support_faceted_browsing
  end
end