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
# do not remove
#  def table_samples_link_list samples
#    #FIXME: make more generic and share with other model link list helper methods
#    samples=samples.select{|s| !s.nil?} #remove nil items
#    return "<span class='none_text'>Not Specified</span>" if samples.empty?
#
#    result=""
#
#     unless samples.blank?
#       result += "<div id='samples' class='samples'><table border='1' cellpadding='10' RULES=COLS FRAME=BOX>"
#
#      samples = samples.sort_by{|ss|ss.tissue_and_cell_types.count}
#      colspan_counts= samples.collect{|s|s.tissue_and_cell_types.count}
#      result +=" <tr>
#              <th>Sample</th>
#              <th>Tissue and cell types</th>
#            </tr> "
#
#       count = 0
#       samples.each do |sample|
#        result += "<tr>"
#        result += "<td ROWSPAN='#{colspan_counts[count]}'>"
#        result += link_to h(sample.title.capitalize),sample
#        result += "</td>"
#
#        if sample
#          sample.tissue_and_cell_types.each do |tt|
#            result += "<td>"
#            result += link_to h(tt.title), tt
#            result += "</td>"
#            result += "</tr>" unless tt==sample.tissue_and_cell_types.first and sample.tissue_and_cell_types.count==1
#            result += "<tr>" unless tt==sample.tissue_and_cell_types.last  and sample.tissue_and_cell_types.count==1
#          end
#        end
#        result += "</tr>"
#         count += 1
#       end
#     result += "</table></div>"
#     end
#    return result
#  end

  def samples_link_list samples
    #FIXME: make more generic and share with other model link list helper methods
    samples=samples.select{|s| !s.nil?} #remove nil items
    return "<span class='none_text'>Not Specified</span>" if samples.empty?

    result=""
    result += "<table cellpadding='10'>"
     samples.each do |sample|

       result += "<tr><td style='text-align:left;'>"
      result += link_to h(sample.title.capitalize),sample


      if sample
        sample.tissue_and_cell_types.each do |tt|
          result += " [" if tt== sample.tissue_and_cell_types.first
          result += link_to h(tt.title), tt
          result += " | " unless tt == sample.tissue_and_cell_types.last
          result += "]" if tt == sample.tissue_and_cell_types.last
        end
      end
      result += "</td></tr>"
     end
     result += "</table>"
    return result
  end

end
