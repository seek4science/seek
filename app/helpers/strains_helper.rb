module StrainsHelper
  def strain_organism_list(organism, none_text = 'Not Specified')
    result = ''
    result = "<span class='none_text'>#{none_text}</span>".html_safe if organism.nil?
    if organism
      result = link_to organism.title, organism, class: 'assay_organism_info'
    end
    result.html_safe
  end
end
