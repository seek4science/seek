module VersionHelper
  
  def data_file_version_path(data_file_version)
    data_file_path(data_file_version.data_file, :version => data_file_version.version)
  end
  
  def sop_version_path(sop_version)
    sop_path(sop_version.sop, :version => sop_version.version)
  end
  
  def model_version_path(model_version)
    model_path(model_version.model, :version => model_version.version)
  end
  
end