# To change this template, choose Tools | Templates
# and open the template in the editor.

module BioPortal
  module BioPortalHelper
    
    BIOPORTAL_BASE_URL = "http://bioportal.bioontology.org"
    BIOPORTAL_REST_BASE_URL = "http://rest.bioontology.org"

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

  end
end
