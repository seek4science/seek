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
  
  def resource_title_draggable_avatar resource
    name = resource.class.name.split("::")[0]
    icon=""
    case name
    when "DataFile","Model","Sop"
      image = image_tag(((name == "Model") ? icon_filename_for_key("model_avatar"): (file_type_icon_url(resource))))
      icon = link_to_draggable(image, show_resource_path(resource), :id=>model_to_drag_id(resource), :class=> "asset", :title=>tooltip_title_attrib(get_object_title(resource)))
    when "Investigation","Study","Publication"
      image = image "#{resource.class.name.downcase}_avatar",{}
      icon = link_to_draggable(image, show_resource_path(resource), :id=>model_to_drag_id(resource), :class=> "asset", :title=>tooltip_title_attrib(get_object_title(resource)))
    when "Assay"
      type=resource.is_modelling? ? "modelling" : "experimental"
      image = image "#{resource.class.name.downcase}_#{type}_avatar",{}
      icon = link_to_draggable(image, show_resource_path(resource), :id=>model_to_drag_id(resource), :class=> "asset", :title=>tooltip_title_attrib(get_object_title(resource)))
    when "Organism"
      image = image "#{resource.class.name.downcase}_avatar",{}
      icon = link_to_draggable(image, organism_path(resource), :id=>model_to_drag_id(resource), :class=> "asset", :title=>tooltip_title_attrib(get_object_title(resource)))
    end
    return icon
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

  #returns true if this permission should not be able to be removed from custom permissions
  #it indicates that this is the management rights for the current user.
  #the logic is that true is returned if the current_user is the contributor of this permission, unless that person is also the contributor of the asset
  def prevent_manager_removal(resource,permission)
    permission.access_type==Policy::MANAGING && permission.contributor==current_user.person && resource.contributor != current_user
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
  def get_related_resources(resource, limit=nil)
    name = resource.class.name.split("::")[0]

    related = {"Person" => {}, "Project" => {}, "Institution" => {}, "Investigation" => {},
      "Study" => {}, "Assay" => {}, "DataFile" => {}, "Model" => {}, "Sop" => {}, "Publication" => {}}

    related.each_key do |key|
      related[key][:items] = []
      related[key][:hidden_count] = 0
      related[key][:extra_count] = 0
    end

    case name
      when "DataFile","Sop","Model"
        related["Project"][:items] = [resource.project]
        related["Study"][:items] = resource.studies   
        related["Assay"][:items] = resource.assays     
      when "Assay"
        related["Project"][:items] = [resource.project]
        related["Investigation"][:items] = [resource.investigation]
        related["Study"][:items] = [resource.study]
        related["DataFile"][:items] = resource.data_files
        related["Model"][:items] = resource.models if resource.is_modelling? #MODELLING ASSAY
        related["Sop"][:items] = resource.sops
      when "Investigation"
        related["Project"][:items] = [resource.project]
        related["Study"][:items] = resource.studies
        related["Assay"][:items] = resource.assays
        related["DataFile"][:items] = resource.data_files
        related["Sop"][:items] = resource.sops
      when "Study"
        related["Project"][:items] = [resource.project]
        related["Investigation"][:items] = [resource.investigation]
        related["Assay"][:items] = resource.assays
        related["DataFile"][:items] = resource.data_files
        related["Sop"][:items] = resource.sops
      when "Organism"
        related["Project"][:items] = resource.projects
        related["Assay"][:items] = resource.assays
        related["Model"][:items] = resource.models        
      when "Person"
        related["Project"][:items] = resource.projects
        related["Institution"][:items] = resource.institutions
        related["Study"][:items] = resource.studies
        if resource.user
          related["DataFile"][:items] = resource.user.data_files
          related["Model"][:items] = resource.user.models
          related["Sop"][:items] = resource.user.sops
        end
        related["DataFile"][:items] = related["DataFile"][:items] | resource.created_data_files
        related["Model"][:items] = related["Model"][:items] | resource.created_models
        related["Sop"][:items] = related["Sop"][:items] | resource.created_sops
        related["Publication"][:items] = related["Model"][:items] | resource.created_publications 
        related["Assay"][:items] = resource.assays
      when "Institution"
        related["Project"][:items] = resource.projects
        related["Person"][:items] = resource.people
      when "Project"
        related["Person"][:items] = resource.people
        related["Institution"][:items] = resource.institutions
        related["Investigation"][:items] = resource.investigations
        related["Study"][:items] = resource.studies
        related["Assay"][:items] = resource.assays
        related["DataFile"][:items] = resource.data_files
        related["Model"][:items] = resource.models
        related["Sop"][:items] = resource.sops
        related["Publication"][:items] = resource.publications
      when "Publication"
        related["Person"][:items] = resource.creators
        related["Project"][:items] = [resource.project]
      else
    end
    
    #Authorize
    ["Sop","Model","DataFile"].each do |asset_type|
      unless related[asset_type][:items].empty?
        total_count = related[asset_type][:items].size
        related[asset_type][:items] = Asset.classify_and_authorize_homogeneous_resources(related[asset_type][:items], true, current_user)
        related[asset_type][:hidden_count] = total_count - related[asset_type][:items].size
      end
    end    
    
    #Limit items viewable, and put the excess count in extra_count
    related.each_key do |key|
      related[key][:items] = related[key][:items].compact
      if limit && related[key][:items].size > limit && ["Project","Investigation","Study","Assay"].include?(resource.class.name)
        related[key][:extra_count] = related[key][:items].size - limit
        related[key][:items] = related[key][:items][0...limit]        
      end
    end

    return related
  end
  
  def filter_url(resource_type, context_resource)
    filter_text = ""
    case context_resource.class.name
      when "Project"
        filter_text = "(:filter => {:project => #{context_resource.id}})"
      when "Investigation"
        filter_text = "(:filter => {:investigation => #{context_resource.id}})"#
      when "Study"
        filter_text = "(:filter => {:study => #{context_resource.id}})"
      when "Assay"
        filter_text = "(:filter => {:assay => #{context_resource.id}})"
    end
    return eval("#{resource_type.underscore.pluralize}_path" + filter_text)
  end

end
