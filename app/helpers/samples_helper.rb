module SamplesHelper


  def sample_strain_list_item sample_strain
    result = link_to h(sample_strain.title),sample_strain

    return result
  end
  def sample_strains_list sample_strains,none_text="Not specified"
    result=""
    result="<span class='none_text'>#{none_text}</span>" if sample_strains.empty?
    sample_strains.each do |ao|
      result += sample_strain_list_item ao
      result += ", " unless ao==sample_strains.last
    end
    result
  end

end
