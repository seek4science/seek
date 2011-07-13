module SpecimensHelper

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