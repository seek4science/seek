module AssetsHelper

  def request_request_label resource
    icon_filename=method_to_icon_filename(resource.class.name.underscore)
    resource_type=resource.class.name.humanize
    return '<span class="icon">' + image_tag(icon_filename,:alt=>"Request",:title=>"Request") + " Request #{resource_type}</span>";
  end

  def resource_version_selection versioned_resource
    versions=versioned_resource.versions

    "<form onsubmit='showResourceVersion(this)'; return false;>"+select_tag(:resource_versions,options_for_select(
            versions.collect{|v| ["#{v.version.to_s} #{versioned_resource.describe_version(v.version)}",url_for(:id=>versioned_resource,:version=>v.version)]} ),
            :onchange=>"showResourceVersion(this.form);"

    )+"</form>"
    
  end

end
