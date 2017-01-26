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

  def modal_openbis_file_view id
    modal_options = { id: id, size: 'xl', 'data-role' => 'modal-openbis-file-view' }

    modal_title = 'DataSet Files'

    modal(modal_options) do
      modal_header(modal_title) +
          modal_body do
            content_tag(:div,'',:id=>:contents)
          end
    end
  end

end