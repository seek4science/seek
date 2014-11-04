module OntologyHelper

  def assay_type_select_tag form, is_modelling,element_id, selected_uri,html_options={}
    type = is_modelling ? "modelling_analysis" : "assay"
    ontology_select_tag form, type ,element_id, selected_uri,html_options
  end

  def technology_type_select_tag form, element_id, selected_uri,html_options={}
    ontology_select_tag form, "technology",element_id,selected_uri,html_options
  end

  def ontology_select_tag form,type,element_id,selected_uri,html_options={}
    options = ontology_select_options(type)
    form.select element_id,options,{:selected=>selected_uri},html_options
  end

  def ontology_select_options(type)
    reader = reader_for_type(type)
    classes = reader.class_hierarchy
    render_ontology_class_options classes
  end

  def render_ontology_class_options clz,depth=0
    result = [["--"*depth+clz.label,clz.uri.to_s]]
    clz.children.each do |c|
      result += render_ontology_class_options(c,depth+1)
    end
    result

  end

  def reader_for_type type
    "Seek::Ontologies::#{type.camelize}TypeReader".constantize.instance
  end

end