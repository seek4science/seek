module AssetsHelper

  def request_request_label resource
    icon_filename=icon_filename_for_key("message")
    resource_type=text_for_resource(resource)
    image_tag(icon_filename,:alt=>"Request",:title=>"Request") + " Request #{resource_type}"
  end

  #returns all the classes for models that return true for is_asset?
  def asset_model_classes
    @@asset_model_classes ||= Seek::Util.persistent_classes.select do |c|
      !c.nil? && c.is_asset?
    end
  end

  def publishing_item_param item
    "publish[#{item.class.name}][#{item.id}]"
  end

  def text_for_resource resource_or_text
    if resource_or_text.is_a?(String)
      text = resource_or_text
    elsif resource_or_text.kind_of?(Specimen)
      text = CELL_CULTURE_OR_SPECIMEN
    else
      text = resource_or_text.class.name
    end
    text.underscore.humanize
  end

  def resource_version_selection versioned_resource, displayed_resource_version
    versions=versioned_resource.versions.reverse
    disabled=versions.size==1
    options=""
    versions.each do |v|
      options << "<option value='#{url_for(:id=>versioned_resource, :version=>v.version)}'"
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
      image=image resource.avatar_key, {}
    elsif resource.use_mime_type_for_avatar?
      image = image file_type_icon_key(resource), {}
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
      path = polymorphic_path(resource.parent, :version=>resource.version, :action=>:download)
    else
      path = polymorphic_path(resource, :action=>:download)
    end
    return path
  end

  #returns true if this permission should not be able to be removed from custom permissions
  #it indicates that this is the management rights for the current user.
  #the logic is that true is returned if the current_user is the contributor of this permission, unless that person is also the contributor of the asset
  def prevent_manager_removal(resource, permission)
    permission.access_type==Policy::MANAGING && permission.contributor==current_user.person && resource.contributor != current_user
  end

  def show_resource_path(resource)
    path = ""
    if resource.class.name.include?("::Version")
      path = polymorphic_path(resource.parent, :version=>resource.version)
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
               "Study" => {}, "Assay" => {}, "Specimen" =>{}, "Sample" => {}, "DataFile" => {}, "Model" => {}, "Sop" => {}, "Publication" => {},"Presentation" => {}, "Event" => {}}

    related.each_key do |key|
      related[key][:items] = []
      related[key][:hidden_count] = 0
      related[key][:extra_count] = 0
    end

    # polymorphic 'related_resource' with ResourceClass#related_resource_type(s),e.g. Person#related_presentations
    related_types = related.keys - [resource.class.name]
    related_types.each do |type|
      method_name = type.underscore.pluralize
      if resource.respond_to? "related_#{method_name}"
        related[type][:items] = resource.send "related_#{method_name}"
      elsif resource.respond_to? method_name
        related[type][:items] = resource.send method_name
      elsif resource.respond_to? "related_#{method_name.singularize}"
         related[type][:items] = [resource.send "related_#{method_name.singularize}"]
      elsif resource.respond_to? method_name.singularize
        related[type][:items] = [resource.send method_name.singularize]
      end
    end

    #Authorize
    related.each do |key,res|
      unless res[:items].empty?
        if key == 'Project' || key == 'Institution'
          total_count = res[:items].size
          res[:hidden_count] = 0
        elsif key == 'Person'
          total_count = res[:items].size
          if Seek::Config.is_virtualliver && current_user.nil?
            res[:items] = []
            res[:hidden_count] = total_count
          else
            res[:hidden_count] = 0
          end
        else
          total_count = res[:items].size
          res[:items] = authorized_related_items res[:items],key
          res[:hidden_count] = total_count - res[:items].size
        end
      end
    end
    
    #Limit items viewable, and put the excess count in extra_count
    related.each_key do |key|
      if limit && related[key][:items].size > limit && ["Project", "Investigation", "Study", "Assay", "Person", "Specimen", "Sample"].include?(resource.class.name)
        related[key][:extra_count] = related[key][:items].size - limit
        related[key][:items] = related[key][:items][0...limit]
      end
    end

    return related
    end

  def authorized_related_items related_items, item_type
    user_id = current_user.nil? ? 0 : current_user.id
    assets = []
    authorized_related_items = []
    lookup_table_name = item_type.underscore + 'auth_lookup'
    asset_class = item_type.constantize
    if (asset_class.lookup_table_consistent?(user_id))
      Rails.logger.info("Lookup table #{lookup_table_name} used for authorizing related items is complete for user_id = #{user_id}")
      assets = asset_class.lookup_for_action_and_user 'view', user_id, nil
      authorized_related_items = assets & related_items
    else
      authorized_related_items = related_items.select(&:can_view?)
    end
    authorized_related_items
  end

  def filter_url(resource_type, context_resource)
    #For example, if context_resource is a project with an id of 1, filter text is "(:filter => {:project => 1}, :page=>'all')"
    filter_text = "(:filter => {:#{context_resource.class.name.downcase} => #{context_resource.id}},:page=>'all')"
    eval("#{resource_type.underscore.pluralize}_path" + filter_text)
  end

  #provides a list of assets, according to the class, that are authorized acording the 'action' which defaults to view
  #if projects is provided, only authorizes the assets for that project
  def authorised_assets asset_class,projects=nil, action="view"
    asset_class.all_authorized_for action, User.current_user, projects
  end

  def asset_buttons asset,version=nil,delete_confirm_message=nil
     human_name = text_for_resource asset
     delete_confirm_message ||= "This deletes the #{human_name} and all metadata. Are you sure?"

     render :partial=>"assets/asset_buttons",:locals=>{:asset=>asset,:version=>version,:human_name=>human_name,:delete_confirm_message=>delete_confirm_message}
  end

  def asset_version_links asset_versions
    asset_version_links = []
    asset_versions.select(&:can_view?).each do |asset_version|
      asset_name = asset_version.class.name.split('::').first.underscore
      asset_version_links << link_to(asset_version.title, eval("#{asset_name}_path(#{asset_version.send("#{asset_name}_id")})") + "?version=#{asset_version.version}", {:target => '_blank'})
    end
    asset_version_links
  end

end
