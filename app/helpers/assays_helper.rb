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
    Authorization.authorize_collection("show",data_files,current_user)
  end

  def assay_organism_list_item assay_organism
    result = link_to h(assay_organism.organism.title),assay_organism.organism
    if assay_organism.strain
      result += ": #{assay_organism.strain.title}"
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
      result += ", " unless ao==assay_organisms.last
    end
    result
  end

  def authorised_assays
    assays=Assay.find(:all)
    Authorization.authorize_collection("show",assays,current_user)
  end
end
