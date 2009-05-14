module OrganismsHelper

  #helper method to help consilidate the fact that organisms are both tags and model entities
  def organism_link_to model_or_tag
    
    if model_or_tag.instance_of?(Organism)
      link_to h(model_or_tag.title.capitalize),model_or_tag
    end

  end

end
