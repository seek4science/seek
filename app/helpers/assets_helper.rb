module AssetsHelper

  def request_request_label resource
    icon_filename=method_to_icon_filename(resource.class.name.underscore)
    resource_type=resource.class.name.humanize
    return '<span class="icon">' + image_tag(icon_filename,:alt=>"Request",:title=>"Request") + " Request #{resource_type}</span>";
  end

end
