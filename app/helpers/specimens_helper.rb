module SpecimensHelper

   def specimen_organism_title specimen
     title = ""
     unless specimen.nil?
       if specimen.organism
       title = specimen.organism.try(:title)
       end
       if specimen.strain
         title += " : #{specimen.strain.try(:title)}"
       end
       if specimen.culture_growth_type
         title += " (#{specimen.culture_growth_type.try(:title)})"
       end
     end
     return title
   end


  def specimen_organism_list organism,strain,culture_growth_type,none_text="Not Specified"
    result=""
    result ="<span class='none_text'>#{none_text}</span>" if organism.nil?
    if organism
      result = link_to h(organism.title),organism,{:class => "assay_organism_info"}

      if strain
        result += " : "
        result += link_to h(strain.title),strain,{:class => "assay_strain_info"}
      end

      if culture_growth_type
        result += " (#{culture_growth_type.title})"
      end
    end
    return result
  end

  def list_item_organism attribute,organism,strain,culture_growth_type
      "<p class=\"list_item_attribute\"><b>#{attribute}</b>: #{specimen_organism_list(organism,strain,culture_growth_type)}</p>"
  end


  def specimens_link_list specimens,sorted=true
    #FIXME: make more generic and share with other model link list helper methods
    specimens=specimens.select{|s| !s.nil?} #remove nil items
    return "<span class='none_text'>Not associated with any Specimens</span>" if specimens.empty?

    result=""
    specimens=specimens.sort{|a,b| a.title<=>b.title} if sorted
    specimens.each do |specimen|
      result += link_to h(specimen.title.capitalize),specimen
      result += " ["
      result += link_to h(specimen.organism.title),specimen.organism,{:class => "assay_organism_info"}

      if specimen.strain
        result += " : "
        result += link_to h(specimen.strain.title),specimen.strain,{:class => "assay_strain_info"}
      end

      if specimen.culture_growth_type
        result += " (#{specimen.culture_growth_type.title})"
      end

      result += "]"

      result += " ,<br/> " unless specimens.last==specimen
    end
    return result
  end

end