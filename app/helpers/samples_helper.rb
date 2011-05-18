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

end
