require 'acts_as_ontology_view_helper'

module AssaysHelper

  include Stu::Acts::Ontology::ActsAsOntologyViewHelper

  #assays that haven't already been associated with a study
  def assays_available_for_study_association
    Assay.where(['study_id IS NULL'])
  end

  def assay_organism_list_item assay_organism
    result = link_to assay_organism.organism.title, assay_organism.organism
    if assay_organism.strain
      result += " : "
      result += h(assay_organism.strain.title)
    end
    if assay_organism.culture_growth_type
      result += " (#{assay_organism.culture_growth_type.title})"
    end
    return result.html_safe
  end

  def authorised_assays projects=nil
    authorised_assets(Assay, projects, "edit")
  end

  def list_assay_samples_and_organisms attribute, assay_samples, assay_organisms, none_text="Not Specified"

    result= "<p class=\"list_item_attribute\"> <b>#{attribute}</b>: "

    result +="<span class='none_text'>#{none_text}</span>" if assay_samples.blank? and assay_organisms.blank?

    assay_samples.each do |as|
      result += "<br/>" if as==assay_samples.first
      organism = as.specimen.organism
      strain = as.specimen.strain
      sample = as
      culture_growth_type = as.specimen.culture_growth_type

      if organism
        result += link_to organism.title, organism, {:class => "assay_organism_info"}
      end

      if strain
        result += " : "
        result += h(strain.title)
      end

      if sample
        result += " : "
        result += link_to sample.title, sample
      end

      if culture_growth_type
        result += " (#{culture_growth_type.title})"
      end
      result += ",<br/>" unless as==assay_samples.last and assay_organisms.blank?
    end

    assay_organisms.each do |ao|
      organism = ao.organism
      strain = ao.strain
      culture_growth_type = ao.culture_growth_type

      result += "<br/>" if assay_samples.blank? and ao==assay_organisms.first
      if organism
        result += link_to organism.title, organism, {:class => "assay_organism_info"}
      end

      if strain
        result += " : "
        result += h(strain.title)
      end

      if culture_growth_type
        result += " (#{culture_growth_type.title})"
      end
      result += ",<br/>" unless ao==assay_organisms.last
    end
    result += "</p>"

    return result.html_safe
  end

  def list_assay_samples attribute, assay_samples, none_text="Not Specified"

    result= "<p class=\"list_item_attribute\"> <b>#{attribute}</b>: "

    result +="<span class='none_text'>#{none_text}</span>" if assay_samples.blank?

    assay_samples.each do |as|

      organism = as.specimen.organism
      strain = as.specimen.strain
      sample = as
      culture_growth_type = as.specimen.culture_growth_type


      if organism
        result += link_to organism.title, organism, {:class => "assay_organism_info"}
      end

      if strain
        result += " : "
        result += h(strain.title)
      end

      if sample
        result += " : "
        result += link_to sample.title, sample
      end

      if culture_growth_type
        result += " (#{culture_growth_type.title})"
      end
      result += ",<br/>" unless as == assay_samples.last

    end

    result += "</p>"
    return result.html_safe
  end

  def list_assay_organisms attribute, assay_organisms, none_text="Not specified"
    result="<p class=\"list_item_attribute\"> <b>#{attribute}</b>: "
    result +="<span class='none_text'>#{none_text}</span>" if assay_organisms.empty?

    assay_organisms.each do |ao|

      organism = ao.organism
      strain = ao.strain
      culture_growth_type = ao.culture_growth_type

      if organism
        result += link_to organism.title, organism, {:class => "assay_organism_info"}
      end

      if strain
        result += " : "
        result += h(strain.title)
      end


      if culture_growth_type
        result += " (#{culture_growth_type.title})"
      end
      result += ",<br/>" unless ao==assay_organisms.last
    end

    result += "</p>"
    return result.html_safe
  end





end
