module SamplesHelper


  def sample_tissue_and_cell_type_list_item sample_tissue_and_cell_type
    result = link_to h(sample_tissue_and_cell_type.title),sample_tissue_and_cell_type

    return result
  end
  def sample_tissue_and_cell_types_list sample_tissue_and_cell_types,none_text="Not specified"
    result=""
    result="<span class='none_text'>#{none_text}</span>" if sample_tissue_and_cell_types.empty?
    sample_tissue_and_cell_types.each do |ao|
      result += sample_tissue_and_cell_type_list_item ao
      result += ", " unless ao==sample_tissue_and_cell_types.last
    end
    result
  end

  def samples_link_list samples,sorted=true
    #FIXME: make more generic and share with other model link list helper methods
    samples=samples.select{|s| !s.nil?} #remove nil items
    return "<span class='none_text'>Not Specified</span>" if samples.empty?

    result=""
    samples=samples.sort{|a,b| a.title<=>b.title} if sorted
    samples.each do |sample|
      result += link_to h(sample.title.capitalize),sample
      result += " | " unless samples.last==sample
    end
    return result
  end

end
