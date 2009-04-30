module SopsHelper

  def authorised_sops
    sops=Sop.find(:all,:include=>:asset)
    Authorization.authorize_collection("show",sops,current_user)
  end

  #returns Sops authorised for the current user, and also filtered for only those related to his/her projects
  def authorised_sops_for_user
    sops=authorised_sops
    projects=current_user.person.projects
    return sops.select{|s| projects.include?(s.asset.project)}
  end

end
