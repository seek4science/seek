module DataFilesHelper

  def authorised_data_files projects=nil
    #authorised_assets(DataFile,projects)
    DataFile.all_authorized_for "view",User.current_user
  end

end
