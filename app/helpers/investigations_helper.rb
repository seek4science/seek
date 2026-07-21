module InvestigationsHelper
  def investigation_link(investigation)
    unless investigation.nil?
      if investigation.can_view?
        code_param = should_include_code_for_isa_link?(investigation) ? params[:code] : nil
        link_to investigation.title, investigation_path(investigation, code: code_param)
      else
        hidden_items_html [investigation]
      end
    else
      "<span class='none_text'>Not associated with an Investigation</span>".html_safe
    end
  end

  def authorised_investigations(projects = nil)
    authorised_assets(Investigation, projects, 'view')
  end

end
