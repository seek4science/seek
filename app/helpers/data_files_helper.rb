module DataFilesHelper
  def authorised_data_files(projects = nil)
    authorised_assets(DataFile, projects)
  end
end
