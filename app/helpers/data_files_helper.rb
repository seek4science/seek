module DataFilesHelper

  def authorised_data_files
    dfs=DataFile.find(:all, :include=>:asset)
    Authorization.authorize_collection("show", dfs, current_user)
  end


end
