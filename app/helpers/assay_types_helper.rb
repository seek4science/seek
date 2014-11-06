#encoding: utf-8
module AssayTypesHelper

  def is_modelling_type? type_class
    type_class.try(:term_type)==Seek::Ontologies::ModellingAnalysisTypeReader::TERM_TYPE
  end

  def link_to_assay_type assay
    parameters={}
    parameters[:uri]=assay.suggested_assay_type.try(:uri) || assay.assay_type_uri
    parameters[:label] = assay.assay_type_label
    link_to parameters[:label], assay_types_path(parameters)
  end

  def parent_types_list_links parents, type
    unless parents.empty?
      parents.collect do |par|
        link_to_ontology_term par, par.label, type, :class => "parent_term"
      end.join(" | ").html_safe
    else
      content_tag :span, "No parent terms", :class => "none_text"
    end
  end

  #FIMXE: these and the technology type helper methods need rejigging and moving to a general helper for types
  #some may be duplicated in ontology_helper
  def parent_assay_types_list_links parents
    parent_types_list_links parents, "assay_type"
  end

  def parent_technology_types_list_links parents
    parent_types_list_links parents, "technology_type"
  end

  def link_to_ontology_term term, label, type, html_options={}
    link_to label, send("#{type}s_path", parameters_for_ontology_term(term)),html_options
  end

  #generates the parameters for a link to assay or technology type, or future type
  #determined by the type and whether it is from the ontology or a suggested term
  def parameters_for_ontology_term term
    parameters={:label => term.label}
    parameters[:uri]=term.uri
    parameters
  end


  def child_assay_types_list_links children
    child_type_links children, "assay_type"
  end

  def child_type_links children, type
    unless children.empty?
      children.collect do |child|
        n = Assay.authorize_asset_collection(child.assays, "view").count
        link_to_ontology_term(child, "#{child.label} (#{n})", type, :class => "child_term")
      end.join(" | ").html_safe
    else
      content_tag :span, "No child terms", :class => "none_text"
    end
  end

end
