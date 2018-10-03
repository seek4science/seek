module DashboardsHelper
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
end
