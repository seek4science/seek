module SopsHelper

  def authorised_sops
    sops=Sop.find(:all,:include=>:asset)
    Authorization.authorize_collection("show",sops,current_user)
  end    
  
  def sop_version_path(sop)
    sop_path(sop, :version => sop.version)
  end
end
