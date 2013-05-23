module AssayTypesHelper
  
  #Displays the ontology with links to edit and remove each node, if requested.
  #Items with an ID matching selected_id are highlighted blue.
  def ontology_editor_display type, show_edit=true, show_delete=true, selected_id=nil
    roots=type.to_tree.sort{|a,b| a.title.downcase <=> b.title.downcase}
    list = []
    roots.each do |root|
      list = list + indented_child_options(root,0,show_edit,show_delete,selected_id)
    end
    
    list.collect do |item|
      (item + "\n").html_safe
    end

  end
  
  #Displays the ontology node with appropriate indentation, as well as optional
  #edit and remove icons, and the number of assays associated with the node.
  def indented_child_options parent,depth=0,show_edit=true,show_delete=true,selected_id=nil
    result = []
    
    unless parent.children.empty?
      parent.children.sort{|a,b| a.title.downcase <=> b.title.downcase}.each do |child|
        result << ("<li style=\"margin-left:#{12*depth}px;#{child.id == selected_id ? "background-color: lightblue;" : ""}\">"+ (depth>0 ? "└ " : " ") + (link_to child.title, child) + " " +
                    (show_edit ? link_to(image("edit"), edit_polymorphic_path(child), {:style=>"vertical-align:middle"}) : "") + " " +
                    (show_delete ? (child.assays.size == 0 ? link_to(image("destroy"),child, :confirm =>
                      "Are you sure you want to remove this #{child.class.name}?  This cannot be undone.",
                      :method => :delete, :style=>"vertical-align:middle") : "<span style=\"color: #666666;\">(#{child.assays.size} assays)</span>") : "") +
                    "</li>").html_safe
        result = result + indented_child_options(child,depth+1,show_edit,show_delete,selected_id) if child.has_children?
      end
    end
    return result
  end
  
  #Displays a combobox to be used in a form where multiple items from an ontology can be selected.
  #Arrays of items to be selected or disabled can be passed to be selected or disabled...  
  def ontology_multiple_select_tag type,id,selected_items=nil,disabled_items=nil,name=nil,size=10
    
    name = id if name.nil?    
    roots=type.to_tree.sort{|a,b| a.title.downcase <=> b.title.downcase}
    options=[]
    roots.each do |root|
      options << [root.title,root.id]
      options = options + child_multiple_select_options(root,1)
    end
    
    selected_options = []
    selected_items.each do |o|
      selected_options << o.id
    end  
    
    disabled_options = []
    disabled_items.each do |o|
      disabled_options << o.id
    end    
    
    select_tag "#{type.name.underscore}[#{name}][]", options_for_select(options, :selected => selected_options, :disabled => disabled_options),
               {:multiple => true, :size => size, :style => "width:300px;"}    
  end
  
  private
  
  def child_multiple_select_options parent,depth=0
    result = []
    
    unless parent.children.empty?
      parent.children.sort{|a,b| a.title.downcase <=> b.title.downcase}.each do |child|
        result << ["---"*depth + child.title,child.id]
        result = result + child_multiple_select_options(child,depth+1) if child.has_children?
      end
    end
    return result
  end
end