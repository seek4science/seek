module OrganismsHelper
  
  #helper method to help consilidate the fact that organisms are both tags and model entities
  def organism_link_to model_or_tag
    return "<span class='none_text'>No Organism specified</span>" if model_or_tag.nil?
    if model_or_tag.instance_of?(Organism)
      link_to model_or_tag.title.capitalize,model_or_tag
    end
  end
  
  def organisms_link_list organisms
    link_list=""
    link_list="<span class='none_text'>No Organisms specified</span>" if organisms.empty?
    organisms.each do |o|
      link_list << organism_link_to(o)
      link_list << ", " unless o==organisms.last   
    end
    link_list.html_safe
  end
  
  def link_to_ncbi_taxonomy_browser organism,text,html_options={}
    html_options[:alt]||=text
    html_options[:title]||=text
    id = organism.ncbi_id
    link_to text,"http://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?mode=info&id=#{id}",html_options
  end
  
  def delete_organism_icon organism
    if organism.can_delete?
      image_tag_for_key('destroy', organism_path(organism), "Delete Organism", { :confirm => 'Are you sure?', :method => :delete }, "Delete Organism")
    else
      explanation="Unable to delete an Organism that is associated with other items."
      html = "<span class='disabled_icon disabled' onclick='javascript:alert(\"#{explanation}\")' data-tooltip='#{tooltip(explanation)}' >"+image('destroy', {:alt=>"Delete",:class=>"disabled"}) + " Delete Organism</span>"
      html.html_safe
    end    
  end

  # takes an array of [organism,strain] where strain can be nil if not defined
  def list_organisms_and_strains organism_and_strains, none_text="Not specified"
    result=""
    result="<span class='none_text'>#{none_text}</span>" if organism_and_strains.empty?
    organism_and_strains.each do |os|
      organism=os[0]
      strain=os[1]
      unless strain.nil? && organism.nil?
        result += organism_and_strain strain,organism
        result += ", " unless os==organism_and_strains.last
      end
    end
    result.html_safe
  end

  def organism_and_strain strain,organism=strain.organism, none_text="Not specified"
    result = ""
    if organism
      result << link_to(h(organism.title), organism)
      if strain && !strain.is_dummy? && strain.can_view?
        result << " : <span class='strain_info'>#{link_to strain.info, strain}</span>"
      elsif strain && !strain.is_dummy? && !strain.can_view?
        result << hidden_items_html([strain], " : hidden strain")
      end
    end
    result.empty? ? "<span class='none_text'>#{none_text}</span>".html_safe : result.html_safe
  end

  def can_create_organisms?
    Organism.can_create?
  end

  def bioportal_search_enabled?
    !Seek::Config.bioportal_api_key.blank?
  end
  
  
end
