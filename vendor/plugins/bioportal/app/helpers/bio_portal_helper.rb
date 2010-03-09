# To change this template, choose Tools | Templates
# and open the template in the editor.


module BioPortalHelper
    
  BIOPORTAL_BASE_URL = "http://bioportal.bioontology.org"
  BIOPORTAL_REST_BASE_URL = "http://rest.bioontology.org"

  def visualise_ontology model,options={}
    options[:show_concept]||=false
    concept_id=nil
    concept_id=model.concept_uri if options[:show_concept] && !model.concept_uri.nil?
    ontology_id=model.ontology_version_id
    ontology_id ||= model.ontology_id
    render(:partial=>"bioportal/bioportal_visualise",:locals=>{:ontology_id=>ontology_id,:concept_id=>concept_id})
  end

  def link_to_concept_id name,concept_id,ontology_version_id,options={},html_options={}
    options[:popup]||=true
    link_to(h(name),BIOPORTAL_BASE_URL+"/visualize/"+ontology_version_id.to_s+"/?conceptid="+URI.encode(concept_id),options,html_options)
  end

  def link_to_ontology name,ontology_id,options={},html_options={}
    options[:popup]||=true
    link_to(h(name),BIOPORTAL_BASE_URL+"/virtual/"+ontology_id.to_s,options,html_options)
  end

  def link_to_ontology_version name,ontology_version_id,options={},html_options={}
    options[:popup]||=true
    link_to(h(name),BIOPORTAL_BASE_URL+"/ontologies/"+ontology_version_id.to_s,options,html_options)
  end

  def link_to_ontology_version_visualize name,ontology_version_id,options={},html_options={}
    options[:popup]||=true
    link_to(h(name),BIOPORTAL_BASE_URL+"/visualize/"+ontology_version_id.to_s,options,html_options)
  end

  def link_to_download_ontology name,ontology_version_id,options={},html_options={}
    link_to(h(name),BIOPORTAL_REST_BASE_URL+"/bioportal/ontologies/download/"+ontology_version_id,options,html_options)
  end

  #options include
  # - name - the name thats used as a prefix to the element names
  # - ontology_ids - arrays of ontology_ids (an element of "all" indicates all ontologies)
  # - no_javascript_include - if present will not include the javascript_include_tag for the bioportal_form_complete.js
  # - value - uri,shortid or name. defaults to name
  def bioportal_form_complete options,html_options={}
    options[:value]||="name"
    result = ""
    result += javascript_include_tag("bioportal_form_complete.js") unless options[:no_javascript_include]

    html_options[:class]="bp_form_complete-#{options[:ontology_ids].join(',')}-#{options[:value]}"
    name = options[:name]
    result += text_field_tag name,nil,html_options
    return result
  end

end

