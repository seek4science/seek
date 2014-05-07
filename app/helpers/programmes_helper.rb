module ProgrammesHelper

  def list_item_programme_attribute(project)
    html = "<p class=\"list_item_attribute\"><b>#{t('programme')}:</b> "
    html << programme_link(project)
    html.html_safe
  end

end
