module FacetedBrowsingHelper
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

  #TODO:   need comment and some tests for this part
  def value_for_key key, config_for_key, object
      facet_value = object
      value_from = config_for_key['value_from']
      value_from.split(':').each do |field|
        if facet_value.blank?
          break
        elsif facet_value.kind_of?(Array) and facet_value.first.respond_to?field
          facet_value = facet_value.collect(&:"#{field}")
        elsif facet_value.respond_to?field
          facet_value = facet_value.send(field)
        elsif !config_for_key['rails_class'].nil? and facet_value.class.name == config_for_key['rails_class']
          next
        else
          facet_value = nil
        end
      end
      facet_value
  end

  def facet_config_path
    File.join(Rails.root, "config", "facets.yml")
  end

  def faceted_search_config_path
    unless Rails.env == 'test'
      File.join(Rails.root, "config", "faceted_search.yml")
    else
      File.join(Rails.root, "test", "fixtures", "files", "faceted_search.txt")
    end
  end

  def one_instance_common_facet_config_path
    unless Rails.env == 'test'
      File.join(Rails.root, "config", "one_instance_common_facets.yml")
    else
      File.join(Rails.root, "test", "fixtures", "files", "faceted_search.txt")
    end
  end

  def one_instance_specified_facet_config_path
    unless Rails.env == 'test'
      File.join(Rails.root, "config", "one_instance_specified_facets.yml")
    else
      File.join(Rails.root, "test", "fixtures", "files", "faceted_search.txt")
    end
  end
end