module SamplesHelper
   def samples_link_list samples
    #FIXME: make more generic and share with other model link list helper methods
    samples=samples.select{|s| !s.nil?} #remove nil items
    return "<span class='none_text'>Not Specified</span>" if samples.empty?

    result=""
    result += "<table cellpadding='10'>"
     samples.each do |sample|

       result += "<tr><td style='text-align:left;'>"
      result += link_to h(sample.title.capitalize),sample

      result += "</td></tr>"
     end
     result += "</table>"
    return result
   end

end
