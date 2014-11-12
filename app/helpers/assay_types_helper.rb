#encoding: utf-8
module AssayTypesHelper

  def is_modelling_type? type_class
    type_class.try(:term_type)==Seek::Ontologies::ModellingAnalysisTypeReader::TERM_TYPE
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

end
