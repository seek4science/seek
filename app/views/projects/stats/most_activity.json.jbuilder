json.cache! "project_dashboard_#{@project.id}_most_#{@activity}", expires_in: 1.day do
  json.array! @most_activity do |asset, count|
    json.resource do
      json.type asset.class.name
      json.id asset.id
      json.title asset.title
      json.href url_for(asset)
      json.avatar asset_path(resource_avatar_path(asset) || icon_filename_for_key("#{asset.class.name.downcase}_avatar"))
    end
    json.count count
  end
end
