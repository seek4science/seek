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

  def samples_link_list samples
    #FIXME: make more generic and share with other model link list helper methods
    samples=samples.select{|s| !s.nil?} #remove nil items
    return "<span class='none_text'>Not Specified</span>" if samples.empty?

    result=""
#    samples=samples.sort{|a,b| a.title<=>b.title} if sorted
#    samples.each do |sample|
#      result += link_to h(sample.title.capitalize),sample
#      result += " | " unless samples.last==sample
#    end

     samples.each do |as|

      organism = as.specimen.organism
      strain = as.specimen.strain
      sample = as
      culture_growth_type = as.specimen.culture_growth_type

      result += link_to h(sample.title.capitalize),sample
      if organism
      #result += link_to h(organism.title),organism,{:class => "assay_organism_info"}
      end

      if strain
       # result += " : "
      #  result += link_to h(strain.title),strain,{:class => "assay_strain_info"}
      end

      if sample
      #  result += " : "
        #result += link_to h(sample.title),sample
        sample.tissue_and_cell_types.each do |tt|
          result += "[" if tt== sample.tissue_and_cell_types.first
          result += link_to h(tt.title), tt
          result += "|" unless tt == sample.tissue_and_cell_types.last
          result += "]" if tt == sample.tissue_and_cell_types.last
        end


      end

      if culture_growth_type
      #  result += " (#{culture_growth_type.title})"
      end
      result += ",<br/>" unless as == samples.last

     end

    return result
  end

end
