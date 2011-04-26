module AssetsHelper

  def request_request_label resource
    icon_filename=icon_filename_for_key("message")
    resource_type=resource.class.name.humanize
    return '<span class="icon">' + image_tag(icon_filename,:alt=>"Request",:title=>"Request") + " Request #{resource_type}</span>";
  end

  #returns all the classes for models that return true for is_asset?
  def asset_model_classes
    @@asset_model_classes ||= Seek::Util.persistent_classes.select do |c|
      !c.nil? && c.is_asset?
    end
  end

  def text_for_resource resource_or_text
    text=resource_or_text.is_a?(String) ? resource_or_text : resource_or_text.class.name
    text = text.underscore.humanize
    text = text.upcase if text.downcase=="sop"
    text
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
    select_tag(:resource_versions,
      options,
      :disabled=>disabled,
      :onchange=>"showResourceVersion($('show_version_form'));"
    ) + "<form id='show_version_form' onsubmit='showResourceVersion(this); return false;'></form>".html_safe
  end
  
  def resource_title_draggable_avatar resource    
    icon=""
    image=nil

    if resource.avatar_key
      image=image resource.avatar_key,{}
    elsif resource.use_mime_type_for_avatar?
      image = image file_type_icon_key(resource),{}
    end

    icon = link_to_draggable(image, show_resource_path(resource), :id=>model_to_drag_id(resource), :class=> "asset", :title=>tooltip_title_attrib(get_object_title(resource))) unless image.nil?
    icon
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
      "Study" => {}, "Assay" => {}, "DataFile" => {}, "Model" => {}, "Sop" => {}, "Publication" => {}, "Event" => {}}

    related.each_key do |key|
      related[key][:items] = []
      related[key][:hidden_count] = 0
      related[key][:extra_count] = 0
    end

    case name
      when "DataFile"
        related["Project"][:items]     = [resource.project]
        related["Study"][:items]       = resource.studies
        related["Assay"][:items]       = resource.assays
        related["Publication"][:items] = resource.related_publications
        related["Event"][:items]      = resource.events
      when "Sop","Model"
        related["Project"][:items] = [resource.project]
        related["Study"][:items] = resource.studies   
        related["Assay"][:items] = resource.assays
        related["Publication"][:items] = resource.related_publications   
      when "Assay"
        related["Project"][:items] = [resource.project]
        related["Investigation"][:items] = [resource.investigation]
        related["Study"][:items] = [resource.study]
        related["DataFile"][:items] = resource.data_files
        related["Model"][:items] = resource.models if resource.is_modelling? #MODELLING ASSAY
        related["Sop"][:items] = resource.sops
        related["Publication"][:items] = resource.related_publications
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
        related["Publication"][:items] = related["Publication"][:items] | resource.created_publications 
        related["Assay"][:items] = resource.assays
      when "Institution"
        related["Project"][:items] = resource.projects
        related["Person"][:items] = resource.people
      when "Project"
        related["Event"][:items] = resource.events
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
        related["DataFile"][:items] = resource.related_data_files
        related["Model"][:items] = resource.related_models
        related["Assay"][:items] = resource.related_assays
        related["Event"][:items] = resource.events
      when "Event"
        {#"Person" => [resource.contributor.try :person], #assumes contributor is a person. Currently that should always be the case, but that could change.
         "Project"     => [resource.project],
         "DataFile"    => resource.data_files,
         "Publication" => resource.publications}.each do |k, v|
          related[k][:items] = v unless v.nil?
        end
      else
    end
    
    #Authorize
    related.each_value do |resource_hash|
      unless resource_hash[:items].empty?
        total_count = resource_hash[:items].size
        resource_hash[:items] = resource_hash[:items].select &:can_view?
        resource_hash[:hidden_count] = total_count - resource_hash[:items].size
      end
    end    
    
    #Limit items viewable, and put the excess count in extra_count
    related.each_key do |key|
      related[key][:items] = related[key][:items].compact
      if limit && related[key][:items].size > limit && ["Project","Investigation","Study","Assay","Person"].include?(resource.class.name)
        related[key][:extra_count] = related[key][:items].size - limit
        related[key][:items] = related[key][:items][0...limit]        
      end
    end

    return related
  end
  
  def filter_url(resource_type, context_resource)
    #For example, if context_resource is a project with an id of 1, filter text is "(:filter => {:project => 1}, :page=>'all')"
    filter_text = "(:filter => {:#{context_resource.class.name.downcase} => #{context_resource.id}},:page=>'all')"
    eval("#{resource_type.underscore.pluralize}_path" + filter_text)
  end

  #provides a list of assets, according to the class, that are authorized to 'show'
  def authorised_assets asset_class
    assets=asset_class.find(:all)
    Authorization.authorize_collection("view",assets,current_user)
  end

end
