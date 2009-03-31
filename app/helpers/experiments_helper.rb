module ExperimentsHelper
  

  def topics_from_assay assay   
    Topic.find(:all,:conditions=>{:project_id=>project_from_assay(assay)})
  end
  
  def project_from_assay assay
    project_id=assay.topic.project.id if !assay.topic.project.nil?
    project_id ||= 0

    return project_id
  end

  def new_topic_to_project_popup_link project_id
    return link_to_remote_redbox("New topic",
      {:url=>new_topic_url(:project_id=>project_id),
        :failure => "alert('Sorry, an error has occurred.'); RedBox.close();" },
      {:id => "create_new_topic_redbox"}
    )
  end

  def new_assay_to_topic_popup_link topic_id
    return link_to_remote_redbox("New assay",
      {:url=>new_assay_url(:topic_id=>topic_id),
        :failure => "alert('Sorry, an error has occurred.'); RedBox.close();" },
      {:id => "create_new_assay_redbox"}
    )
  end

end
