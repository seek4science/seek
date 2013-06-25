module SpecimensHelper

  def specimen_organism_list organism,strain,culture_growth_type=nil,none_text="Not Specified"
    result=""
    result ="<span class='none_text'>#{none_text}</span>".html_safe if organism.nil?
    if organism
      result = link_to h(organism.title),organism,{:class => "assay_organism_info"}

      if strain && !strain.is_dummy? && strain.can_view?
        result += " : <span class='strain_info'>#{link_to h(strain.info), strain}</span>".html_safe
      elsif strain && !strain.is_dummy? && !strain.can_view?
        result += hidden_items_html [strain], " : hidden strain"
      end

      if culture_growth_type
        result += " (#{culture_growth_type.title})"
      end
    end
    return result.html_safe
  end

  def sex_list_for_selection
    sex_list = [["male",0], ["female",1]]
    sex_list |= Seek::Config.is_virtualliver ? [["hermaphrodite",2]] : [["F+",2],["F-",3]]
    sex_list
  end

end