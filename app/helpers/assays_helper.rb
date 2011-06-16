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
  def show_assay_organisms_list assay_organisms,none_text="Not specified"
    result=""
    result="<span class='none_text'>#{none_text}</span>" if assay_organisms.empty?

    assay_organisms.each do |ao|

      organism = ao.organism
      strain = ao.try(:strain)
      tissue_and_cell_type = try_block{ao.tissue_and_cell_type}
      culture_growth_type = ao.try(:culture_growth_type)

      if organism
      result += link_to h(organism.title),organism,{:class => "assay_organism_info"}
      end

      if strain
        result += " : "
        result += link_to h(strain.title),strain,{:class => "assay_strain_info"}
      end

      if tissue_and_cell_type
        result += " : "
        result += link_to h(tissue_and_cell_type.title),tissue_and_cell_type,{:class => "assay_tissue_and_cell_type_info"}

      end

      if culture_growth_type
        result += " (#{culture_growth_type.title})"
      end
      result += ",<br/>" unless ao == assay_organisms.last

    end
    result
  end

  def show_specimen_organisms_list specimens,none_text="Not specified"
    result=""
    result="<span class='none_text'>#{none_text}</span>" if specimens.empty?
    organisms = specimens.collect{|s|[s.organism,s.strain,s.culture_growth_type]}.uniq

    organisms.each do |ao|

      organism = ao.first
      strain = ao.second
      culture_growth_type = ao.third

      if organism
      result += link_to h(organism.title),organism,{:class => "assay_organism_info"}
      end

      if strain
        result += " : "
        result += link_to h(strain.title),strain,{:class => "assay_strain_info"}
      end

      if culture_growth_type
        result += " (#{culture_growth_type.title})"
      end
      result += ",<br/>" unless ao == organisms.last

    end
    result

  end

  def authorised_assays
    Assay.all.select{|assay| assay.can_edit?(current_user)}
  end


  def list_assay_samples attribute,assay_samples, none_text="Not Specified"

    result= "<p class=\"list_item_attribute\"> <b>#{attribute}</b>: "

    result +="<span class='none_text'>#{none_text}</span>" if assay_samples.blank?

    assay_samples.each do |as|

      organism = as.specimen.organism
      strain = as.specimen.strain
      sample = as
      culture_growth_type = as.specimen.culture_growth_type

      if organism
      result += link_to h(organism.title),organism,{:class => "assay_organism_info"}
      end

      if strain
        result += " : "
        result += link_to h(strain.title),strain,{:class => "assay_strain_info"}
      end

      if sample
        result += " : "
        #result += link_to h(sample.title),sample
        sample.tissue_and_cell_types.each do |tt|
          result += "[" if tt== sample.tissue_and_cell_types.first
          result += link_to h(tt.title), tt
          result += "|" unless tt == sample.tissue_and_cell_types.last
          result += "]" if tt == sample.tissue_and_cell_types.last
        end


      end

      if culture_growth_type
        result += " (#{culture_growth_type.title})"
      end
      result += ",<br/>" unless as == assay_samples.last

    end

    result += "</p>"
    return result
  end

  def list_assay_organisms attribute,assay_organisms,none_text="Not specified"
    result="<p class=\"list_item_attribute\"> <b>#{attribute}</b>: "
    result +="<span class='none_text'>#{none_text}</span>" if assay_organisms.empty?

    organism=nil
    strain = nil
    culture_growth_type=nil

    organisms =[]
    strains =[]
    culture_growth_types =[]
    tissue_and_cell_types = []

    group_count = 0

    assay_organisms.each do |ao|

       if organism == ao.organism and strain == ao.strain and culture_growth_type == ao.culture_growth_type
            tissue_and_cell_types[group_count].push ao.tissue_and_cell_type
       else
          organism = ao.organism
          strain = ao.strain
          tissue_and_cell_type = ao.tissue_and_cell_type
          culture_growth_type = ao.culture_growth_type

          organisms[group_count] = organism
          strains[group_count] = strain
          culture_growth_types[group_count] = culture_growth_type

          group_count += 1
          tissue_and_cell_types[group_count] =[]
          tissue_and_cell_types[group_count].push(tissue_and_cell_type)
       end
    end

    for group_index in 1..group_count do

        organism = organisms[group_index-1]
        strain = strains[group_index-1]
        culture_growth_type = culture_growth_types[group_index-1]

        one_group_tissue_and_cell_types = tissue_and_cell_types[group_index]

        if organism
            result += link_to h(organism.title),organism,{:class => "assay_organism_info"}
        end

        if strain
          result += " : "
          result += link_to h(strain.title),strain,{:class => "assay_strain_info"}
        end
        if one_group_tissue_and_cell_types

          one_group_tissue_and_cell_types.each do |tt|
            if tt
              result += " [" if tt== one_group_tissue_and_cell_types.first
              result += link_to h(tt.title), tt
              result += "|" unless tt == one_group_tissue_and_cell_types.last
              result += "]" if tt == one_group_tissue_and_cell_types.last
            end
          end
        end

        if culture_growth_type
          result += " (#{culture_growth_type.title})"
        end
        result += ",<br/>" unless group_index==group_count
      end

    result += "</p>"
    return result
  end

end
