module OntologyHelper
  def assay_type_select_tag(form, is_modelling, element_id, selected_uri, html_options = {})
    type = is_modelling ? 'modelling_analysis' : 'assay'
    ontology_select_tag form, type, element_id, selected_uri, html_options
  end

  def technology_type_select_tag(form, element_id, selected_uri, html_options = {})
    ontology_select_tag form, 'technology', element_id, selected_uri, html_options
  end

  def ontology_select_tag(form, type, element_id, selected_uri, html_options = {})
    options = ontology_select_options(type)
    form.select element_id, options, { selected: selected_uri }, html_options
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
    unless children.empty?
      children.map do |child|
        n = Assay.authorize_asset_collection(child.assays, 'view').count
        link_to_ontology_term(child, "#{child.label} (#{n})", type, class: 'child_term')
      end.join(' | ').html_safe
    else
      content_tag :span, 'No child terms', class: 'none_text'
    end
  end
end
