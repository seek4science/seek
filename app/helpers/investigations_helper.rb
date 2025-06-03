module InvestigationsHelper
  def investigation_link(investigation)
    unless investigation.nil?
      if investigation.can_view?
        link_to investigation.title, investigation
      else
        hidden_items_html [investigation]
      end
    else
      "<span class='none_text'>Not associated with an Investigation</span>".html_safe
    end
  end

  def show_update_from_fair_data_station_button?(investigation)
    Seek::Config.fair_data_station_enabled && investigation.external_identifier.present? && investigation.can_manage?
  end

  def authorised_investigations(projects = nil)
    authorised_assets(Investigation, projects, 'view')
  end

  def fair_data_station_investigation_updates_to_show(investigation, contributor)
    FairDataStationUpload.for_investigation_and_contributor(investigation, contributor).show_status.update_purpose.select do |upload|
      upload.update_task.in_progress? || upload.update_task.completed?
    end
  end

  def fair_data_station_investigation_updates_in_progress?(investigation, contributor)
    fair_data_station_investigation_updates_to_show(investigation, contributor).any? do |upload|
      upload.update_task.in_progress?
    end
  end

end
