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
        yield if block_given?
      end
    end
  end

  def resource_with_count(asset, count)
    avatar = resource_avatar_path(asset) || icon_filename_for_key("#{asset.class.name.downcase}_avatar")
    link_to(asset, title: "#{asset.class.name.humanize} - #{asset.title}", target: :_blank, class: 'mini-resource-list-item') do
      content_tag(:span, class: 'mini-resource-list-text') do
        image_tag(asset_path(avatar), class: 'mini-resource-list-avatar') +
            content_tag(:span, asset.title, class: 'mini-resource-list-title')
      end +
      content_tag(:span, count, class: 'mini-resource-list-count')
    end
  end

  def dates_between(start_date, end_date, interval = 'month')
    case interval
    when 'year'
      transform = -> (date) { Date.parse("#{date.strftime('%Y')}-01-01") }
      increment = -> (date) { date >> 12 }
    when 'month'
      transform = -> (date) { Date.parse("#{date.strftime('%Y-%m')}-01") }
      increment = -> (date) { date >> 1 }
    when 'day'
      transform = -> (date) { date }
      increment = -> (date) { date + 1 }
    else
      raise 'Invalid interval. Valid intervals: year, month, day'
    end

    start_date = transform.call(start_date)
    end_date = transform.call(end_date)
    date = start_date
    dates = []

    while date <= end_date
      dates << date
      date = increment.call(date)
    end

    dates
  end
end
