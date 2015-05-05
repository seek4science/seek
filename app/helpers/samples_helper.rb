module SamplesHelper


  def sample_tissue_and_cell_type_list_item sample_tissue_and_cell_type
    result = link_to h(sample_tissue_and_cell_type.title),sample_tissue_and_cell_type

    return result.html_safe
  end
  def sample_tissue_and_cell_types_list sample_tissue_and_cell_types,none_text="Not specified"
    result=""
    result="<span class='none_text'>#{none_text}</span>" if sample_tissue_and_cell_types.empty?
    sample_tissue_and_cell_types.each do |ao|
      result += sample_tissue_and_cell_type_list_item ao
      result += ", " unless ao==sample_tissue_and_cell_types.last
    end
    result.html_safe
  end


  def samples_link_list samples
    #FIXME: make more generic and share with other model link list helper methods
    samples=samples.select{|s| !s.nil?} #remove nil items
    return "<span class='none_text'>Not Specified</span>".html_safe if samples.empty?

    result=""
    result += "<table cellpadding='10'>"
     samples.each do |sample|

       result += "<tr><td style='text-align:left;'>"
      result += link_to sample.title.capitalize,sample


      if sample
        result += describe_sample_tissue_and_cell_types(sample)
      end
      result += "</td></tr>"
     end
     result += "</table>"
    return result.html_safe
   end

  def describe_sample_tissue_and_cell_types(sample)
    result = ""
    sample.tissue_and_cell_types.each do |tt|
      result += " [" if tt== sample.tissue_and_cell_types.first
      result += link_to h(tt.title), tt
      result += " | " unless tt == sample.tissue_and_cell_types.last
      result += "]" if tt == sample.tissue_and_cell_types.last
    end
    result
  end

end
