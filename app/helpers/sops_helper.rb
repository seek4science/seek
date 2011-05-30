module SopsHelper

  def authorised_sops
    sops = Sop.all
    Authorization.authorize_collection("view",sops,current_user)
  end    

end