module StudiesHelper
  
  

  def new_investigation_to_project_popup_link project_id
    return link_to_remote_redbox("Create",
      {:url=>new_investigation_redbox_url(:project_id=>project_id),
        :failure => "alert('Sorry, an error has occurred.'); RedBox.close();" },
      {:id => "create_new_investigation_redbox"}
    )
  end

  def new_assay_to_investigation_popup_link investigation_id
    return link_to_remote_redbox("New assay",
      {:url=>new_assay_url(:investigation_id=>investigation_id),
        :failure => "alert('Sorry, an error has occurred.'); RedBox.close();" },
      {:id => "create_new_assay_redbox"}
    )
  end

  # generates the HTML to display the project avatar and named link
  def related_project_avatar project
    project_title = h(project.name)
    project_url = project_path(project)
    image_tag=avatar(project,60,false,project_url,project_title,false)
    project_link=link_to project_title, project_url, :alt=>project_title


    return (image_tag + "<p style='margin: 0; text-align: center;'>#{project_link}</p>").html_safe
  end

  def sorted_measured_items
    items=MeasuredItem.find(:all)
    items.sort{|a,b| a.title <=> b.title}
  end

  def studies_link_list studies,sorted=true
    #FIXME: make more generic and share with other model link list helper methods
    studies=studies.select{|s| !s.nil?} #remove nil items
    return "<span class='none_text'>Not associated with any Studies</span>" if studies.empty?

    result=""
    studies=studies.sort{|a,b| a.title<=>b.title} if sorted
    studies.each do |study|
      result += link_to h(study.title.capitalize),study
      result += " | " unless studies.last==study
    end
    return result.html_safe
  end

end
