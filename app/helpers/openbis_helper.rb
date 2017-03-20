module OpenbisHelper
  def can_browse_openbis?(project, user = User.current_user)
    Seek::Config.openbis_enabled && project.has_member?(user) && project.openbis_endpoints.any?
  end

  def modal_openbis_file_view(id)
    modal_options = { id: id, size: 'xl', 'data-role' => 'modal-openbis-file-view' }

    modal_title = 'DataSet Files'

    modal(modal_options) do
      modal_header(modal_title) +
        modal_body do
          content_tag(:div, '', id: :contents)
        end
    end
  end

  def openbis_datafile_dataset(data_file)
    dataset = data_file.content_blob.openbis_dataset
    if dataset.error_occurred?
      render partial: 'data_files/openbis/dataset_error'
    else
      render partial: 'data_files/openbis/dataset', locals: { dataset: dataset, data_file: data_file }
    end
  end
end
