# encoding: utf-8

module SuggestedTypesHelper
  def suggested_type_modal_boxes
    boxes = suggested_type_modal_box(@assay.assay_type_reader.ontology_term_type)
    boxes << suggested_type_modal_box(@assay.technology_type_reader.ontology_term_type) unless @assay.is_modelling?
    boxes
  end

  def suggested_type_modal_box(term_type)
    modal_id = "#{term_type.underscore.downcase}-new-term-modal"
    modal_options = { id: modal_id, size: 's', 'data-role' => 'create-new-suggested-type' }
    suggested_type = if term_type == 'technology'
                       SuggestedTechnologyType.new
                     else
                       SuggestedAssayType.new
                     end
    suggested_type.term_type = term_type

    modal_title = "New suggested #{term_type.humanize.downcase} type"

    modal(modal_options) do
      modal_header(modal_title) +
        modal_body do
          render partial: 'suggested_types/new_modal_type', locals: { suggested_type: suggested_type }
        end
    end
  end

  def create_suggested_type_popup_link(term_type)
    link_name = image('new') + ' ' + "New #{term_type.humanize.downcase} type"
    modal_id = "#{term_type.underscore.downcase}-new-term-modal"

    link_to(link_name, '#', 'data-toggle' => 'modal', 'data-target' => "##{modal_id}")
  end

  def create_or_update_text
    submit_button_text = action_name == 'edit' ? 'Update' : 'Create'
    submit_button_text
  end

  def all_types_text(join_word = 'and')
    model_class = controller_name.classify.constantize
    model_class.all_term_types.map { |type| type.split('_').join(' ') }.join(" #{join_word} ")
  end

  def cancel_link
    if is_ajax_request?
      link_to_function('Cancel', "$j('.modal:visible').modal('toggle');", class: 'btn btn-default')
    else
      manage_path = eval "#{controller_name}_path"
      cancel_button(manage_path)
    end
  end

  def ontology_editor_display(types, selected_uri = nil)
    list = []
    Array(types).each do |type|
      list += render_list(type, selected_uri)
    end
    list.join("\n").html_safe
  end

  def render_list(type, selected_uri = nil)
    reader = reader_for_type(type)
    classes = reader.class_hierarchy
    render_ontology_class_tree(classes, selected_uri)
  end

  def render_ontology_class_tree(clz, selected_uri, depth = 0)
    list = []
    uri = clz.uri.try(:to_s)
    clz_li = "<li#{uri == selected_uri ? ' class="selected"' : ''}>#{ontology_class_list_item(clz)}"
    list << clz_li
    list << '<ul>' if clz.children.any?
    clz.children.each do |ontology_class_or_suggested_type|
      list += render_ontology_class_tree(ontology_class_or_suggested_type, selected_uri, depth + 1)
    end
    list << '</ul>' if clz.children.any?
    list << '</li>'
    list
  end

  def ontology_class_list_item(clz)
    list_item = show_ontology_class_link(clz)
    list_item += '* ' if clz.suggested_type?
    list_item += edit_ontology_class_link(clz) + delete_ontology_class_link(clz) + related_assays_text(clz)
    list_item.html_safe
  end

  def related_assays_text(clz)
    count = clz.assays.size
    count == 0 ? '' : " <span style='color: #666666;'>(#{pluralize(count, 'assay')})</span>".html_safe
  end

  def show_ontology_class_link(clz)
    label = clz.label
    type = clz.term_type
    raise 'error' if type.nil?
    path = send("#{type}_types_path", uri: clz.uri.try(:to_s), label: label)
    html_options = clz.suggested_type? ? { style: 'color:green;font-style:italic' } : {}
    link_to label, path, html_options
  end

  def edit_ontology_class_link(clz)
    link = if clz.can_edit?
             new_popup_request? ? popup_link_to_edit(clz) : normal_link_to_edit(clz)
           else
             ''
           end
    link.html_safe
  end

  def delete_ontology_class_link(clz)
    link = if clz.can_destroy?
             link_to image('destroy'), clz, data: { confirm: "Are you sure you want to remove this #{clz.term_type} type?  This cannot be undone." },
                                            method: :delete
           else
             ''
           end
    link.html_safe
  end

  def normal_link_to_edit(clz)
    link_to(image('edit'), send("edit_suggested_#{clz.term_type}_type_path", id: clz))
  end

  def popup_link_to_edit(clz)
    type = clz.term_type
    link_to_with_callbacks(image('edit'), html: { remote: true, method: :get },
                                          url: send("edit_suggested_#{type}_type_path", id: clz, term_type: type),
                                          method: :get,
                                          loading: "$('RB_redbox').scrollTo();Element.show('edit_suggested_type_spinner'); Element.hide('new_suggested_#{type}_type_form')",
                                          loaded: "Element.hide('edit_suggested_type_spinner'); Element.show('new_suggested_#{type}_type_form')")
  end

  def new_popup_request?
    action_name == 'new' && is_ajax_request?
  end

  def is_ajax_request?
    request.xhr?
  end
end
