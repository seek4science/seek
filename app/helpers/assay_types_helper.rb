#encoding: utf-8
module AssayTypesHelper
  #Displays the ontology with links to edit and remove each node, if requested.
  #Items with an ID matching selected_id are highlighted blue.
  def ontology_editor_display type, show_edit=true, show_delete=true, selected_id=nil
    roots=type.to_tree.sort{|a,b| a.title.downcase <=> b.title.downcase}
    list = []
    roots.each do |root|
      list = list + indented_child_options(root,0,show_edit,show_delete,selected_id)
    end
    list = list.join("\n").html_safe
    list = list + "<br/> <em>* Note that it is created by seek user.</em>".html_safe
  end

  #Displays the ontology node with appropriate indentation, as well as optional
  #edit and remove icons, and the number of assays associated with the node.
  def indented_child_options parent,depth=0,show_edit=true,show_delete=true,selected_id=nil
    result = []

    unless parent.children.empty?
      parent.children.sort{|a,b| a.title.downcase <=> b.title.downcase}.each do |child|
        result << ("<li style=\"margin-left:#{12*depth}px;#{child.id == selected_id ? "background-color: lightblue;" : ""}\">"+ (depth>0 ? "└ " : " ") + (link_to child.title, child,{:style=>"#{child.is_user_defined ? "color:green;font-style:italic": ""}"}) + "#{child.is_user_defined ? "*" : ""}"+" " +
                    (show_edit ? link_to(image("edit"), edit_polymorphic_path(child), {:style=>"vertical-align:middle"}) : "") + " " +
                    (show_delete ? (child.assays.size == 0 ? link_to(image("destroy"),child, :confirm =>
                      "Are you sure you want to remove this #{child.class.name}?  This cannot be undone.",
                      :method => :delete, :style=>"vertical-align:middle") : "<span style=\"color: #666666;\">(#{child.assays.size} assays)</span>") : "") +
                    "</li>")
        result = result + indented_child_options(child,depth+1,show_edit,show_delete,selected_id) if child.has_children?
      end
    end
    return result
  end
  def link_to_assay_type assay
    uri = assay.assay_type_uri
    label = assay.assay_type_label
    if assay.valid_assay_type_uri?
      link_to label,assay_types_path(:uri=>uri,:label=>label)
    else
      label
    end
  end

  def parent_assay_types_list_links parents
    unless parents.empty?
      parents.collect do |par|
        link_to par.label,assay_types_path(uri: par.uri,label: par.label),:class=>"parent_term"
      end.join(" | ").html_safe
    else
      content_tag :span,"No parent terms",:class=>"none_text"
    end
  end


  def child_assay_types_list_links children
    child_type_links children,"assay_type"
  end

  def child_type_links children,type
    unless children.empty?
      children.collect do |child|
        uris = child.flatten_hierarchy.collect{|o| o.uri.to_s}
        assays = Assay.where("#{type}_uri".to_sym => uris)
        n = Assay.authorize_asset_collection(assays,"view").count
        path = send("#{type}s_path",:uri=>child.uri,:label=>child.label)

        link_to "#{child.label} (#{n})",path,:class=>"child_term"
      end.join(" | ").html_safe
    else
      content_tag :span,"No child terms",:class=>"none_text"
    end
  end

  #the display of the label, with an indication of the actual label if the label presented is a temporary label awaiting addition to the ontology
  def displayed_hierarchy_current_label declared_label, defined_class
    result = h(declared_label)
    if !defined_class.nil? && defined_class.label.try(:downcase)!=declared_label.try(:downcase)
      comment = "  - this is a new suggested term that specialises #{defined_class.label}"
      result << content_tag("span",comment,:class=>"none_text")
    end
    result.html_safe
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