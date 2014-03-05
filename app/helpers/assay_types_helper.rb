#encoding: utf-8
module AssayTypesHelper
  def create_assay_type_popup_link default_parent_id, controller_name="assay_types"
      return link_to_remote_redbox(image("new") + ' new assay type',
       { :url => new_assay_type_path ,
         :failure => "alert('Sorry, an error has occurred.'); RedBox.close();",
         :with => "'default_parent_id=#{default_parent_id}' + '&link_from=#{controller_name}'"
       }
  )
  end



  def link_to_assay_type assay
    uri = assay.assay_type.term_uri
    label = assay.assay_type.label
    if assay.valid_assay_type_uri?
      link_to label,assay_types_path(:uri=>uri,:label=>label)
    else
      label
    end
  end

  def parent_assay_types_list_links parents
    unless parents.empty?
      parents.collect do |par|
        link_to par.label,assay_types_path(:uri=>par.term_uri,:label=>par.label),:class=>"parent_term"
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
        n = Assay.authorize_asset_collection(child.assays,"view").count
        path = send("#{type}s_path", :uri=>child.term_uri,:label=>child.label)

        link_to "#{child.title} (#{n})", path,:class=>"child_term"
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