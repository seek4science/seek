module FacetedBrowsingHelper
  def exhibit_tree tree_class, facet
    tree = []
    class_hierarchy = tree_class.constantize.instance.class_hierarchy
    tree.push({'type' => facet, 'label' => class_hierarchy.label})
    tree |=  generate_tree(class_hierarchy, facet)
    tree
  end

  def generate_tree parent_class, facet
    result = []
    parent_class.subclasses.each do |child|
      result << {'type' => facet, 'label' => child.label, 'subclassOf' => child.parents.first.label}
      result = result + generate_tree(child, facet) unless child.subclasses.empty?
    end
    result
  end
end