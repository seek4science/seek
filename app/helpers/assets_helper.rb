module AssetsHelper

  def request_request_label resource
    icon_filename=icon_filename_for_key(resource.class.name.underscore)
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
    if class_name.end_with?("::Version")
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

  #Get a hash of appropriate related resources for the given resource. Also returns a hash of hidden resources
  def get_related_resources(resource)
    name = resource.class.name.split("::")[0]

    related = {"people" => {}, "projects" => {}, "institutions" => {}, "investigations" => {},
      "studies" => {}, "assays" => {}, "data_files" => {}, "models" => {}, "sops" => {}}

    related_hidden = {"sops" => 0, "models" => 0, "data_files" => 0}

    case name
      when "DataFile","Sop"
        related["projects"] = classify_for_tabs([resource.project])
        related["assays"] = classify_for_tabs(resource.assays)
        related["studies"] = classify_for_tabs(resource.studies)
      when "Model"
        related["projects"] = classify_for_tabs([resource.project])
      when "Assay"
        related["sops"] = Asset.classify_and_authorize_resources(resource.sops, true, current_user)
        related_hidden["sops"] = resource.sops.size - (related["sops"]["Sop"] || []).size
        related["data_files"] = Asset.classify_and_authorize_resources(resource.data_files, true, current_user)
        related_hidden["data_files"] = resource.data_files.size - (related["data_files"]["DataFile"] || []).size
        related["studies"] = classify_for_tabs([resource.study])
        related["projects"] = classify_for_tabs([resource.project])
        related["investigations"] = classify_for_tabs([resource.investigation])
      when "Investigation"
        related["sops"] = Asset.classify_and_authorize_resources(resource.sops, true, current_user)
        related_hidden["sops"] = resource.sops.size - (related["sops"]["Sop"] || []).size
        related["data_files"] = Asset.classify_and_authorize_resources(resource.data_files, true, current_user)
        related_hidden["data_files"] = resource.data_files.size - (related["data_files"]["DataFile"] || []).size
        related["studies"] = classify_for_tabs(resource.studies)
        related["projects"] = classify_for_tabs([resource.project])
        related["assays"] = classify_for_tabs(resource.assays)
      when "Study"
        related["sops"] = Asset.classify_and_authorize_resources(resource.sops, true, current_user)
        related_hidden["sops"] = resource.sops.size - (related["sops"]["Sop"] || []).size
        related["data_files"] = Asset.classify_and_authorize_resources(resource.data_files, true, current_user)
        related_hidden["data_files"] = resource.data_files.size - (related["data_files"]["DataFile"] || []).size
        related["projects"] = classify_for_tabs([resource.project])
        related["assays"] = classify_for_tabs(resource.assays)
      when "Organism"
        related["models"] = Asset.classify_and_authorize_resources(resource.models, true, current_user)
        related_hidden["models"] = resource.models.size - (related["models"]["Model"] || []).size
        related["projects"] = classify_for_tabs(resource.projects)
        related["assays"] = classify_for_tabs(resource.assays)
      when "Person"
        if resource.user
          assets_hash = split_assets_by_type(resource.user.assets | resource.created_assets)
        else
          assets_hash = split_assets_by_type(resource.created_assets)
        end
        related["data_files"] = Asset.classify_and_authorize_resources(assets_hash[:data_files], true, current_user)
        related_hidden["data_files"] = assets_hash[:data_files].size - (related["data_files"]["DataFile"] || []).size
        related["sops"] = Asset.classify_and_authorize_resources(assets_hash[:sops], true, current_user)
        related_hidden["sops"] = assets_hash[:sops].size - (related["sops"]["Sop"] || []).size
        related["models"] = Asset.classify_and_authorize_resources(assets_hash[:models], true, current_user)
        related_hidden["models"] = assets_hash[:models].size - (related["models"]["Model"] || []).size
        related["studies"] = classify_for_tabs(resource.studies)
        related["projects"] = classify_for_tabs(resource.projects)
        related["institutions"] = classify_for_tabs(resource.institutions)
      when "Institution"
        related["projects"] = classify_for_tabs(resource.projects)
        related["people"] = classify_for_tabs(resource.people)
      when "Project"
        assets_hash = split_assets_by_type(resource.assets)
        related["data_files"] = Asset.classify_and_authorize_resources(assets_hash[:data_files], true, current_user)
        related_hidden["data_files"] = assets_hash[:data_files].size - (related["data_files"]["DataFile"] || []).size
        related["sops"] = Asset.classify_and_authorize_resources(assets_hash[:sops], true, current_user)
        related_hidden["sops"] = assets_hash[:sops].size - (related["sops"]["Sop"] || []).size
        related["models"] = Asset.classify_and_authorize_resources(assets_hash[:models], true, current_user)
        related_hidden["models"] = assets_hash[:models].size - (related["models"]["Model"] || []).size
        related["institutions"] = classify_for_tabs(resource.institutions)
        related["people"] = classify_for_tabs(resource.people)
        related["assays"] = classify_for_tabs(resource.assays)
        related["studies"] = classify_for_tabs(resource.studies)
        related["investigations"] = classify_for_tabs(resource.investigations)
      else
    end
    hash = {}
    related.each_value{|res_hash| hash.merge!(res_hash) unless res_hash.empty?}

    return hash, related_hidden
  end

  def split_assets_by_type(asset_list)
    hash = {:data_files => [], :models => [], :sops => []}
    asset_list.each do |a|
      case a.resource_type
        when "Sop"
          hash[:sops] << a.resource
        when "Model"
          hash[:models] << a.resource
        when "DataFile"
          hash[:data_files] << a.resource
      end
    end
    return hash
  end

end
