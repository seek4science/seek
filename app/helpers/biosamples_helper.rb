module BiosamplesHelper
  def create_strain_popup_link
     return link_to_remote_redbox(image_tag("famfamfam_silk/add.png") + 'Create new strain',
      { :url => url_for(:controller => 'biosamples', :action => 'create_strain_popup') ,
        :failure => "alert('Sorry, an error has occurred.'); RedBox.close();",
        :with => "'strain_id=' + getSelectedStrains()",
        :condition => "checkSelectOneStrain()"
      }
      #,
      #:alt => "Click to create a new favourite group (opens popup window)",#options[:tooltip_text],
      #:title => tooltip_title_attrib("Opens a popup window, where you can create a new favourite<br/>group, add people to it and set individual access rights.") }  #options[:tooltip_text]
    )
  end

   def create_sample_popup_link
     return link_to_remote_redbox(image_tag("famfamfam_silk/add.png") + 'Create new sample',
      { :url => url_for(:controller => 'biosamples', :action => 'create_sample_popup') ,
        :failure => "alert('Sorry, an error has occurred.'); RedBox.close();",
        :with => "'specimen_id=' + getSelectedSpecimens()",
        :condition => "checkSelectOneSpecimen('#{CELL_CULTURE_OR_SPECIMEN}')"
      }
      #,
      #:alt => "Click to create a new favourite group (opens popup window)",#options[:tooltip_text],
      #:title => tooltip_title_attrib("Opens a popup window, where you can create a new favourite<br/>group, add people to it and set individual access rights.") }  #options[:tooltip_text]
    )
  end
end
