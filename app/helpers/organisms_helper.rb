module OrganismsHelper

  #helper method to help consilidate the fact that organisms are both tags and model entities
  def organism_link_to model_or_tag
    return "<span class='none_text'>No organism specified</span>" if model_or_tag.nil?
    if model_or_tag.instance_of?(Organism)
      link_to h(model_or_tag.title.capitalize),model_or_tag
    end
  end

  def organisms_link_list organisms
    link_list=""
    link_list="<span class='non_text'>No organisms specified</span>" if organisms.empty?
    organisms.each do |o|
         link_list << organism_link_to(o)
         link_list << ", " unless o==organisms.last   
      end
    return link_list    
  end

end
