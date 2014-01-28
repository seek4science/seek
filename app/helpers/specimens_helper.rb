module SpecimensHelper

  def specimen_organism_list organism,strain,culture_growth_type=nil,none_text="Not Specified"
    result=""
    result ="<span class='none_text'>#{none_text}</span>".html_safe if organism.nil?
    if organism
      result = link_to organism.title,organism,{:class => "assay_organism_info"}

      if strain && !strain.is_dummy? && strain.can_view?
        result += " : <span class='strain_info'>#{link_to strain.info, strain}</span>".html_safe
      elsif strain && !strain.is_dummy? && !strain.can_view?
        result += hidden_items_html [strain], " : hidden strain"
      end

      if culture_growth_type
        result += " (#{culture_growth_type.title})"
      end
    end
    return result.html_safe
  end

#  def table_specimens_link_list specimens,sorted=true
#    #FIXME: make more generic and share with other model link list helper methods
#    specimens=specimens.select{|s| !s.nil?} #remove nil items
#    return "<span class='none_text'>Not associated with any Specimens</span>" if specimens.empty?
#
#    result=""
#    unless specimens.blank?
#      result += "<div id='specimens' class='specimens'><table border='1' cellpadding='10' >"
#
#      specimens=specimens.sort{|a,b| a.title<=>b.title} if sorted
#
#      result +=" <tr>
#              <th>Specimen</th>
#              <th colspan='3'>Organism | Strain | Culture growth type</th></tr>"
#
#      specimens.each do |specimen|
#
#        result +="<tr>"
#        result +="<td>"
#        result += link_to h(specimen.title.capitalize),specimen
#        result +="</td>"
#
#        result +="<td>"
#        result += link_to h(specimen.organism.title),specimen.organism,{:class => "assay_organism_info"}
#        result += "</td>"
#
#        result +="<td>"
#        if specimen.strain
#          result += link_to h(specimen.strain.title),specimen.strain,{:class => "assay_strain_info"}
#        end
#        result += "</td>"
#        result +="<td>"
#        if specimen.culture_growth_type
#          result += "#{specimen.culture_growth_type.title}"
#        end
#        result += "</td>"
#        result += "<tr>"
#      end
#      result += "</table></div>"
#    end
#    return result
#  end


  def sex_list_for_selection
    sex_list = [["male",0], ["female",1]]
    sex_list |= Seek::Config.is_virtualliver ? [["hermaphrodite",2]] : [["F+",2],["F-",3]]
    sex_list
  end

end