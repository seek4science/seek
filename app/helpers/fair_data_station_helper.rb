module FairDataStationHelper
  def fair_data_station_close_status_button(fair_data_station_upload, purpose)
    extra_options = {}
    if purpose.to_s == 'import'
      extra_options = { 'data-project-id': fair_data_station_upload.project.id, 'data-purpose': 'import' }
    elsif purpose.to_s == 'update'
      extra_options = { 'data-investigation-id': fair_data_station_upload.investigation.id, 'data-purpose': 'update' }
    else
      raise 'Unknown Purpose for FDS upload close button'
    end
    content_tag(:button, { class: 'close close-status-button', 'aria-label': 'Close',
                           'data-upload-id': fair_data_station_upload.id }.merge(extra_options)) do
      content_tag(:span, 'aria-hidden': true) do
        '&times;'.html_safe
      end
    end
  end

  def fair_data_station_imports_to_show(project, contributor)
    FairDataStationUpload.import_purpose
                         .joins(:import_task)
                         .for_project_and_contributor(project, contributor)
                         .show_status
                         .where(tasks: { status: [Task::STATUS_QUEUED, Task::STATUS_ACTIVE, Task::STATUS_DONE,
                                                  Task::STATUS_FAILED] })
                         .order(id: :desc)
  end

  def fair_data_station_investigation_updates_to_show(investigation, contributor)
    FairDataStationUpload.update_purpose
                         .joins(:update_task)
                         .for_investigation_and_contributor(investigation, contributor)
                         .show_status
                         .where(tasks: { status: [Task::STATUS_QUEUED, Task::STATUS_ACTIVE, Task::STATUS_DONE,
                                                  Task::STATUS_FAILED] })
                         .order(id: :desc)
  end

  def fair_data_station_investigation_updates_in_progress?(investigation, contributor)
    fair_data_station_investigation_updates_to_show(investigation, contributor).any? do |upload|
      upload.update_task.in_progress?
    end
  end

  def show_update_from_fair_data_station_button?(investigation)
    Seek::Config.fair_data_station_enabled && investigation.external_identifier.present? && investigation.can_manage?
  end
end
