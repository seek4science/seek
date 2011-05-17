module SpecimensHelper

   def specimen_organism_list_item attribute,specimen,none_text="Not specified"
    result = "<span class='none_text'>#{none_text}</span>"
    unless specimen.nil?
    result = link_to h(specimen.organism.try(:title)),specimen.organism
    if specimen.strain
      result += ": #{specimen.strain.try(:title)}"
    end
    if specimen.culture_growth_type
      result += " (#{specimen.culture_growth_type.try(:title)})"
    end
    end

    return "<p class=\"list_item_attribute\"><b>#{attribute}</b>: #{result}</p>"
   end
   def specimen_organism_title specimen
     title = ""
     unless specimen.nil?
       title = specimen.organism.try(:title)
       if specimen.strain
         title += ": #{specimen.strain.try(:title)}"
       end
       if specimen.culture_growth_type
         title += " (#{specimen.culture_growth_type.try(:title)})"
       end
     end
     return title
   end

end