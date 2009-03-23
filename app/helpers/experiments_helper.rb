module ExperimentsHelper
  

  def topics_from_assay assay   
    Topic.find(:all,:conditions=>{:project_id=>project_from_assay(assay)})
  end
  
  def project_from_assay assay
    project_id=assay.topic.project.id if !assay.topic.project.nil?
    project_id ||= 0

    return project_id
  end

end
