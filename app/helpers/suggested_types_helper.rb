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



  def destroy_errors suggested_type
    return nil if suggested_type.can_destroy?
    error_messages = []
    error_messages << "Unable to delete #{suggested_type.humanize_term_type} types with children." if !suggested_type.children.empty?
    error_messages << "Unable to delete #{suggested_type.humanize_term_type} type " \
                                 "due to reliance from #{suggested_type.assays.count} " \
                                 "existing #{suggested_type.humanize_term_type}." if !suggested_type.assays.empty?
    error_messages.join("<br/>").html_safe
  end

  def cancel_link
    if  is_ajax_request?
      link_to_function("Cancel", "RedBox.close()")
    else
      manage_path = eval "manage_#{self.controller_name}_path"
      link_to("Cancel", manage_path)
    end
  end


  #select tag without form
  def ontology_selection_list types, element_name, selected_uri, disabled_uris={}, html_options={}
    options = []
    Array(types).each do |type|
      options += ontology_select_options(type)
    end
    select_tag element_name, options_for_select(options, :selected => selected_uri, :disabled => disabled_uris), html_options
  end


  def ontology_editor_display types, selected_uri=nil
    list = []
    Array(types).each do |type|
      list += render_list(type, selected_uri)
    end
    list = list.join("\n").html_safe
    list = list + "<br/> <em>* Note that it is suggested term.</em>".html_safe
    list
  end

  def render_list type, selected_uri=nil
    reader = reader_for_type(type)
    classes = reader.class_hierarchy
    list = render_ontology_class_tree(classes, type, selected_uri)
    list
  end

  def render_ontology_class_tree clz, type, selected_uri, depth=0
    list = []
    uri = clz.uri.try(:to_s)
    clz_li = "<li style=\"margin-left:#{12*depth}px;#{uri == selected_uri ? "background-color: lightblue;" : ""}\">" + (depth>0 ? "└ " : " ") + ontology_class_list_item(clz, type) + "</li>"
    list << clz_li
    clz.children.each do |c|
      list +=render_ontology_class_tree(c, type, selected_uri, depth+1)
    end

    list
  end

  def ontology_class_list_item clz, type
    list_item = show_ontology_class_link(clz, type)
    list_item += "* " if  clz.is_suggested_type?
    list_item += edit_ontology_class_link(clz, type)
    list_item += delete_ontology_class_link(clz, type)
    list_item += related_assays_text(clz.assays)
    list_item.html_safe
  end

  def related_assays_text(assays)
    assays.size == 0 ? "" : "<span style='color: #666666;'>(#{pluralize(assays.size, "assay")})</span>".html_safe
  end

  def show_ontology_class_link clz, type
    path = send("#{type}_types_path", :uri => clz.uri.try(:to_s), :label => clz.label)
    html_options = clz.is_suggested_type? ? {:style => "color:green;font-style:italic"} : {}
    link_to clz.label, path, html_options
  end

  def edit_ontology_class_link clz, type
    link = if clz.can_edit?
             new_popup_request? ? popup_link_to_edit(clz, type) : normal_link_to_edit(clz, type)
           else
             ""
           end
    link.html_safe
  end

  def delete_ontology_class_link clz, type
    link = if clz.can_destroy? && action_name =="manage"
             link_to image("destroy"), clz, :confirm => "Are you sure you want to remove this #{type} type?  This cannot be undone.",
                     :method => :delete,
                     :style => "vertical-align:middle"
           else
             ""
           end
    link.html_safe
  end

  def normal_link_to_edit clz, type
    link_to(image("edit"), send("edit_suggested_#{type}_type_path", :id => clz), {:style => "vertical-align:middle"})
  end

  def popup_link_to_edit clz, type
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
    request.xhr? == 0
  end

end