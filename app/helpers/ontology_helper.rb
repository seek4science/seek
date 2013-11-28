module OntologyHelper

  def assay_type_select_tag form, element_id, selected_uri,html_options={}
    ontology_select_tag form, "assay",element_id, selected_uri,html_options
  end

  def technology_type_select_tag form, element_id, selected_uri,html_options={}
    ontology_select_tag form, "technology",element_id,selected_uri,html_options
  end


  def ontology_select_tag form,type,element_id,selected_uri,html_options={}
    reader = reader_for_type(type)
    classes = reader.class_hierarchy
    options = render_ontology_class_options classes
    form.select element_id,options,{:selected=>selected_uri},html_options
  end

  def render_ontology_class_options clz,depth=0
    result = [["--"*depth+clz.label,clz.uri.to_s]]
    clz.subclasses.each do |c|
      result += render_ontology_class_options(c,depth+1)
    end
    result

  end

  def reader_for_type type
    "Seek::Ontologies::#{type.capitalize}TypeReader".constantize.new
  end

end