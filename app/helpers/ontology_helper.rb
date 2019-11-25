module OntologyHelper
  def assay_type_select_tag(element_name, is_modelling, assay, html_options = {})
    type = is_modelling ? 'modelling_analysis' : 'assay'

    ontology_select_tag element_name, type, selected_assay_type_uri(assay), html_options
  end

  def technology_type_select_tag(element_name, assay, html_options = {})
    ontology_select_tag element_name, 'technology', selected_technology_type_uri(assay), html_options
  end

  def ontology_select_tag(element_name, type, selected_uri, html_options = {})
    ontology_selection_list([type], element_name, selected_uri, {}, html_options)
  end

  # ontology select tag when form is unavailable
  def ontology_selection_list(types, element_name, selected_uri, disabled_uris = {}, html_options = {})
    options = []
    Array(types).each do |type|
      options += ontology_select_options(type)
    end
    select_options = options_for_select(options, selected: selected_uri, disabled: disabled_uris)
    select_tag element_name, select_options, html_options
  end

  def ontology_select_options(type)
    reader = reader_for_type(type)
    classes = reader.class_hierarchy
    render_ontology_class_options classes
  end

  def render_ontology_class_options(clz, depth = 0)
    result = [['--' * depth + clz.label, clz.uri.to_s]]
    clz.children.each do |child|
      result += render_ontology_class_options(child, depth + 1)
    end
    result
  end

  def link_to_assay_type(assay)
    parameters = parameters_for_type(assay, 'assay_type')
    link_to parameters[:label], assay_types_path(parameters)
  end

  def link_to_technology_type(assay)
    parameters = parameters_for_type(assay, 'technology_type')
    link_to parameters[:label], technology_types_path(parameters)
  end

  def parameters_for_type(assay, type)
    {
      label: assay.send("#{type}_label"),
      uri: assay.send("suggested_#{type}").try(:uri) || assay.send("#{type}_uri")
    }
  end

  def child_technology_types_list_links(children)
    child_type_links children, 'technology_type'
  end

  def reader_for_type(type)
    "Seek::Ontologies::#{type.camelize}TypeReader".constantize.instance
  end

  def parent_assay_types_list_links(parents)
    parent_types_list_links parents, 'assay_type'
  end

  def parent_technology_types_list_links(parents)
    parent_types_list_links parents, 'technology_type'
  end

  def link_to_ontology_term(term, label, type, html_options = {})
    link_to label, send("#{type}s_path", parameters_for_ontology_term(term)), html_options
  end

  # generates the parameters for a link to assay or technology type, or future type
  # determined by the type and whether it is from the ontology or a suggested term
  def parameters_for_ontology_term(term)
    parameters = { label: term.label }
    parameters[:uri] = term.uri
    parameters
  end

  def child_assay_types_list_links(children)
    child_type_links children, 'assay_type'
  end

  def child_type_links(children, type)
    if children.empty?
      content_tag :span, 'No child terms', class: 'none_text'
    else
      children.map do |child|
        n = child.assays.authorized_for('view').count
        link_to_ontology_term(child, "#{child.label} (#{n})", type, class: 'child_term')
      end.join(' | ').html_safe
    end
  end

  # the assay type selected in the dropdown box. If there is a suggested type applied, then uri is based on that type and id
  def selected_assay_type_uri(assay)
    assay.suggested_assay_type ? "suggested_assay_type:#{assay.suggested_assay_type.id}" : assay.assay_type_uri
  end

  # the technology type selected in the dropdown box. If there is a suggested type applied, then uri is based on that type and id
  def selected_technology_type_uri(assay)
    assay.suggested_technology_type ? "suggested_technology_type:#{assay.suggested_technology_type.id}" : assay.technology_type_uri
  end
end
