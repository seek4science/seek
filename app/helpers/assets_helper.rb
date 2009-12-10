module AssetsHelper

  def request_request_label resource
    icon_filename=method_to_icon_filename(resource.class.name.underscore)
    resource_type=resource.class.name.humanize
    return '<span class="icon">' + image_tag(icon_filename,:alt=>"Request",:title=>"Request") + " Request #{resource_type}</span>";
  end

  def resource_version_selection versioned_resource,displayed_resource_version
    versions=versioned_resource.versions.reverse
    disabled=versions.size==1
    options=""
    versions.each do |v|
      options << "<option value='#{url_for(:id=>versioned_resource,:version=>v.version)}'"
      options << " selected='selected'" if v.version==displayed_resource_version.version
      options << "> #{v.version.to_s} #{versioned_resource.describe_version(v.version)} </option>"
    end
    "<form onsubmit='showResourceVersion(this); return false;' style='text-align:right;'>"+select_tag(:resource_versions,
                                                                            options,
                                                                            :disabled=>disabled,
                                                                            :onchange=>"showResourceVersion(this.form);"

    )+"</form>"
    
  end
  
  def get_original_model_name(model)
    class_name = model.class.name
    if class_name.ends_with?("::Version")
      class_name = class_name.split("::")[0]
    end
    class_name
  end

  #Changed these so they can cope with non-asset things such as studies, assays etc.
  def download_resource_path(resource)
    path = ""
    if resource.class.name.include?("::Version")
      path = polymorphic_path(resource.parent,:version=>resource.version,:action=>:download)
    else
      path = polymorphic_path(resource,:action=>:download)
    end
    return path
  end

  def show_resource_path(resource)
    path = ""
    if resource.class.name.include?("::Version")
      path = polymorphic_path(resource.parent,:version=>resource.version)
    else
      path = polymorphic_path(resource)
    end
    return path
  end

  def edit_resource_path(resource)
    path = ""
    if resource.class.name.include?("::Version")
      path = edit_polymorphic_path(resource.parent)
    else
      path = edit_polymorphic_path(resource)
    end
    return path
  end

end
