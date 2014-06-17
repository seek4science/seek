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

  def facet_config_path
    unless Rails.env == 'test'
      File.join(Rails.root, "config", "facets.yml")
    else
      File.join(Rails.root, "test", "fixtures", "files", "facets.txt")
    end
  end

  def faceted_search_config_path
    unless Rails.env == 'test'
      File.join(Rails.root, "config", "faceted_search.yml")
    else
      File.join(Rails.root, "test", "fixtures", "files", "faceted_search.txt")
    end
  end

  def one_instance_facet_config_path
    unless Rails.env == 'test'
      File.join(Rails.root, "config", "one_instance_faceted_search.yml")
    else
      File.join(Rails.root, "test", "fixtures", "files", "faceted_search.txt")
    end
  end
end