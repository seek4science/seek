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

   def create_sample_popup_link
     return link_to_remote_redbox(image_tag("famfamfam_silk/add.png") + 'Create new sample',
      { :url => url_for(:controller => 'samples', :action => 'create_sample_popup') ,
        :failure => "alert('Sorry, an error has occurred.'); RedBox.close();"
      }
      #,
      #:alt => "Click to create a new favourite group (opens popup window)",#options[:tooltip_text],
      #:title => tooltip_title_attrib("Opens a popup window, where you can create a new favourite<br/>group, add people to it and set individual access rights.") }  #options[:tooltip_text]
    )
  end

end
