module OrganismsHelper

  #helper method to help consilidate the fact that organisms are both tags and model entities
  def organism_link_to model_or_tag
    return "<span class='none_text'>No Organism specified</span>" if model_or_tag.nil?
    if model_or_tag.instance_of?(Organism)
      link_to h(model_or_tag.title.capitalize),model_or_tag
    end
  end

  def organisms_link_list organisms
    link_list=""
    link_list="<span class='non_text'>No Organisms specified</span>" if organisms.empty?
    organisms.each do |o|
         link_list << organism_link_to(o)
         link_list << ", " unless o==organisms.last   
      end
    return link_list    
  end

  def link_to_ncbi_taxonomy_browser organism,text,html_options={}
    html_options[:alt]||=text
    html_options[:title]||=text
    concept_uri=organism.concept_uri
    ncbi_id=concept_uri.split(":")[1]
    link_to h(text),"http://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?mode=info&id=#{ncbi_id}",html_options
  end

end
