module DataFilesHelper

  def authorised_data_files
    data_files=DataFile.find(:all,:include=>:asset)
    Authorization.authorize_collection("show",data_files,current_user)
  end
  
end
