module BiosamplesHelper
  def create_strain_popup_link
     return link_to_remote_redbox(image_tag("famfamfam_silk/add.png") + 'Create new strain',
      { :url => url_for(:controller => 'biosamples', :action => 'create_strain_popup') ,
        :failure => "alert('Sorry, an error has occurred.'); RedBox.close();",
        :with => "'strain_id=' + getSelectedStrains()+'&organism_ids='+$F('strain_organism_ids')",
        :condition => "checkSelectOneStrain()"
      }
      #,
      #:alt => "Click to create a new favourite group (opens popup window)",#options[:tooltip_text],
      #:title => tooltip_title_attrib("Opens a popup window, where you can create a new favourite<br/>group, add people to it and set individual access rights.") }  #options[:tooltip_text]
    )
  end

   def create_sample_popup_link
     return link_to_remote_redbox(image_tag("famfamfam_silk/add.png") + 'Create new sample and '+ CELL_CULTURE_OR_SPECIMEN,
      { :url => url_for(:controller => 'biosamples', :action => 'create_sample_popup') ,
        :failure => "alert('Sorry, an error has occurred.'); RedBox.close();",
        :with => "'specimen_id=' + getSelectedSpecimens()+'&organism_ids='+$F('strain_organism_ids')",
        :condition => "checkSelectOneSpecimen('#{CELL_CULTURE_OR_SPECIMEN}')"
      }
      #,
      #:alt => "Click to create a new favourite group (opens popup window)",#options[:tooltip_text],
      #:title => tooltip_title_attrib("Opens a popup window, where you can create a new favourite<br/>group, add people to it and set individual access rights.") }  #options[:tooltip_text]
    )
   end
   def organism_selection_onchange_function
     function =  remote_function(:url=>{:action=>"existing_strains", :controller=>"biosamples"},
                                                      :with=>"'organism_ids='+$F('strain_organism_ids')",
                                                      :before=>"show_ajax_loader('existing_strains')")+ ";"
     function += remote_function(:url => {:controller => 'biosamples', :action => 'existing_specimens'},
                                                                  :with => "'strain_ids=' + getSelectedStrains() + '&organism_ids='+$F('strain_organism_ids')") + ";"  if Seek::Config.is_virtualliver
     function +=  "check_show_existing_items('strain_organism_ids', 'existing_strains', '');"
     function += "hide_existing_specimens();hide_existing_samples();" unless Seek::Config.is_virtualliver
     function += "return(false);"
     function
   end

  def strain_checkbox_onchange_function
        function = remote_function(:url => {:controller => 'biosamples', :action => 'existing_specimens'}, :with => "'strain_ids=' + getSelectedStrains()+'&organism_ids='+$F('strain_organism_ids')") +";"
        function += "show_existing_specimens();hide_existing_samples();" unless Seek::Config.is_virtualliver
        function += "return(false);"
        function
  end
end
