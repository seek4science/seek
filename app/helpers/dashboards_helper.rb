module DashboardsHelper

  def dashboard_panel(title, id, options = {})
    options = merge_options({ class: "dashboard-panel panel #{options[:type] || 'panel-default'}", id: id }, options)

    content_tag(:div, options) do # The panel wrapper
      content_tag(:div, class: 'panel-heading') do
        button_tag(class: 'btn-default btn btn-xs dashboard-refresh-btn pull-right') do
          content_tag(:span, ' ', class: 'glyphicon glyphicon-refresh') + ' Refresh'
        end + title
      end +
      content_tag(:div, class: 'panel-body') do
        yield
      end
    end
  end

end
