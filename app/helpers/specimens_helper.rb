module SpecimensHelper

   def specimen_organism_list_item specimen_organism
    result = link_to h(specimen_organism.organism.title),specimen_organism.organism
    if specimen_organism.strain
      result += ": #{specimen_organism.strain.title}"
    end
    if specimen_organism.culture_growth_type
      result += " (#{specimen_organism.culture_growth_type.title})"
    end
    return result
   end

  def specimen_organisms_list organism_specimens,none_text="Not specified"
    result=""
    result="<span class='none_text'>#{none_text}</span>" if organism_specimens.empty?
    organism_specimens.each do |ao|
      result += specimen_organism_list_item ao
      result += ", " unless ao==organism_specimens.last
    end
    result
  end

end