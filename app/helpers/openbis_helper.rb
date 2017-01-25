module OpenbisHelper
  def dataset_file_list_item(data_file,file)
    raise "Not an openBIS data file" unless data_file.openbis?
    result = file.path
    size = content_tag(:em){" (#{number_to_human_size(file.size)})"}
    download = image_tag_for_key('download', polymorphic_path([data_file, data_file.content_blobs.first], :action=>:download,:code=>params[:code],perm_id:file.file_perm_id), "Download", {:title => 'Download this file'}, "")


    (result + size + download).html_safe
  end

  def can_browse_openbis?(project,user=User.current_user)
    Seek::Config.openbis_enabled && project.has_member?(user) && project.openbis_endpoints.any?
  end

end