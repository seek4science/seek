require 'acts_as_ontology_view_helper'

module AssaysHelper
  
  include Stu::Acts::Ontology::ActsAsOntologyViewHelper  

  #assays that haven't already been associated with a study
  def assays_available_for_study_association
    Assay.find(:all,:conditions=>['study_id IS NULL'])
  end

  #only data files authorised for show, and belonging to projects matching current_user
  def data_files_for_assay_association
    data_files=DataFile.find(:all,:include=>:asset)
    data_files=data_files.select{|df| current_user.person.projects.include?(df.project)}
    Authorization.authorize_collection("view",data_files,current_user)
  end

  def assay_organism_list_item assay_organism
    result = link_to h(assay_organism.organism.title),assay_organism.organism
    if assay_organism.strain
       result += " : "
       result += link_to h(assay_organism.strain.title),assay_organism.strain,{:class => "assay_strain_info"}
    end

    if assay_organism.tissue_and_cell_type
      result += " : "
      result += link_to h(assay_organism.tissue_and_cell_type.title),assay_organism.tissue_and_cell_type,{:class => "assay_tissue_and_cell_type_info"}
    end

    if assay_organism.culture_growth_type
      result += " (#{assay_organism.culture_growth_type.title})"
    end
    return result
  end
  def assay_organisms_list assay_organisms,none_text="Not specified"
    result=""
    result="<span class='none_text'>#{none_text}</span>" if assay_organisms.empty?
    assay_organisms.each do |ao|
      result += assay_organism_list_item ao
      result += ",<br/>" unless ao==assay_organisms.last
    end
    result
  end

  def authorised_assays
    Assay.all.select{|assay| assay.can_edit?(current_user)}
  end

  def assay_sample_organism_list organism,strain,sample,culture_growth_type, none_text="Not Specified"
    result=""
    result ="<span class='none_text'>#{none_text}</span>" if organism.nil?
    if organism
      result = link_to h(organism.title),organism,{:class => "assay_organism_info"}

      if strain
        result += " : "
        result += link_to h(strain.title),strain,{:class => "assay_strain_info"}
      end

      if sample
        result += " : "
        result += link_to h(sample.title),sample
      end

      if culture_growth_type
        result += " (#{culture_growth_type.title})"
      end
    end
    return result
  end

  def list_assay_sample_organism attribute,organism,strain,sample,culture_growth_type
      "<p class=\"list_item_attribute\"><b>#{attribute}</b>: #{assay_sample_organism_list(organism,strain,sample,culture_growth_type)}</p>"
  end
end
