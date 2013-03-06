module StrainsHelper
  def strain_organism_list organism,none_text="Not Specified"
      result=""
      result ="<span class='none_text'>#{none_text}</span>" if organism.nil?
      if organism
        result = link_to h(organism.title),organism,{:class => "assay_organism_info"}
      end
      return result
  end
end
