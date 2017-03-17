module VersionHelper
  def data_file_version_path(data_file_version)
    data_file_path(data_file_version.parent, version: data_file_version.version)
  end

  def sop_version_path(sop_version)
    sop_path(sop_version.parent, version: sop_version.version)
  end

  def model_version_path(model_version)
    model_path(model_version.parent, version: model_version.version)
  end

  def presentation_version_path(presentation_version)
    presentation_path(presentation_version.parent, version: presentation_version.version)
  end

  def data_file_version_url(data_file_version)
    data_file_url(data_file_version.parent, version: data_file_version.version)
  end

  def sop_version_url(sop_version)
    sop_url(sop_version.parent, version: sop_version.version)
  end

  def model_version_url(model_version)
    model_url(model_version.parent, version: model_version.version)
  end

  def presentation_version_url(presentation_version)
    presentation_url(presentation_version.parent, version: presentation_version.version)
  end
end
