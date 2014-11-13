#encoding: utf-8
module SuggestedTypesHelper
  def create_suggested_type_popup_link term_type
    link_name = image('new') + " " + "new #{term_type.humanize.downcase} type"
    url = eval "new_suggested_#{term_type}_type_path"

    return link_to_remote_redbox(link_name,
                                 {:url => url,
                                  :failure => "alert('Sorry, an error has occurred.'); RedBox.close();",
                                  :with => "'term_type=#{term_type}'",
                                  :method => :get
                                 }
    )
  end

  def create_or_update_text
    submit_button_text = action_name=="edit" ? "Update" : "Create"
    submit_button_text
  end


  def all_types_text join_word="and"
    model_class = controller_name.classify.constantize
    model_class.all_term_types.map{|type| type.split("_").join(" ")}.join(" #{join_word} ")
  end


  def cancel_link
    if  is_ajax_request?
      link_to_function("Cancel", "RedBox.close()")
    else
      manage_path = eval "manage_#{self.controller_name}_path"
      link_to("Cancel", manage_path)
    end
  end

  def ontology_editor_display types, selected_uri=nil
    list = []
    Array(types).each do |type|
      list += render_list(type, selected_uri)
    end
    list = list.join("\n").html_safe + "<br/> <em>* Note that it is suggested term.</em>".html_safe
  end

  def render_list type, selected_uri=nil
    reader = reader_for_type(type)
    classes = reader.class_hierarchy
    list = render_ontology_class_tree(classes, selected_uri)
    list
  end

  def render_ontology_class_tree clz, selected_uri, depth=0
    list = []
    uri = clz.uri.try(:to_s)
    clz_li = "<li style=\"margin-left:#{12*depth}px;#{uri == selected_uri ? "background-color: lightblue;" : ""}\">" + (depth>0 ? "└ " : " ") + ontology_class_list_item(clz) + "</li>"
    list << clz_li
    clz.children.each do |ontology_class_or_suggested_type|
      list +=render_ontology_class_tree(ontology_class_or_suggested_type, selected_uri, depth+1)
    end
    list
  end

  def ontology_class_list_item clz
    list_item = show_ontology_class_link(clz)
    list_item += "* " if  clz.is_suggested_type?
    list_item += edit_ontology_class_link(clz) + delete_ontology_class_link(clz) + related_assays_text(clz)
    list_item.html_safe
  end

  def related_assays_text(clz)
    count = clz.assays.size
    count == 0 ? "" : "<span style='color: #666666;'>(#{pluralize(count, "assay")})</span>".html_safe
  end

  def show_ontology_class_link clz
    label = clz.label
    type = clz.term_type
    raise "error" if type.nil?
    path = send("#{type}_types_path", :uri => clz.uri.try(:to_s), :label => label)
    html_options = clz.is_suggested_type? ? {:style => "color:green;font-style:italic"} : {}
    link_to label, path, html_options
  end

  def edit_ontology_class_link clz
    link = if clz.can_edit?
             new_popup_request? ? popup_link_to_edit(clz) : normal_link_to_edit(clz)
           else
             ""
           end
    link.html_safe
  end

  def delete_ontology_class_link clz
    link = if clz.can_destroy? && action_name =="manage"
             link_to image("destroy"), clz, :confirm => "Are you sure you want to remove this #{clz.term_type} type?  This cannot be undone.",
                     :method => :delete,
                     :style => "vertical-align:middle"
           else
             ""
           end
    link.html_safe
  end

  def normal_link_to_edit clz
    link_to(image("edit"), send("edit_suggested_#{clz.term_type}_type_path", :id => clz), {:style => "vertical-align:middle"})
  end

  def popup_link_to_edit clz
    type = clz.term_type
    link_to_with_callbacks(image("edit"), :html => {:remote => true, :method => :get},
                           :url => send("edit_suggested_#{type}_type_path", :id => clz, :term_type => type),
                           :method => :get,
                           :loading => "$('RB_redbox').scrollTo();Element.show('edit_suggested_type_spinner'); Element.hide('new_suggested_#{type}_type_form')",
                           :loaded => "Element.hide('edit_suggested_type_spinner'); Element.show('new_suggested_#{type}_type_form')"
    )
  end

  def new_popup_request?
    action_name == "new" && is_ajax_request?
  end

  def is_ajax_request?
    request.xhr?
  end

end