module ModelsHelper

  def model_environment_text model
    model.recommended_environment ? h(model.recommended_environment.title) : "<span class='none_text'>Not specified</span>".html_safe
  end


  def execute_model_label
    icon_filename=icon_filename_for_key("execute")
    html = '<span class="icon">' + image_tag(icon_filename,:alt=>"Run",:title=>"Run") + ' Run model</span>';
    html.html_safe
  end

  def model_type_text model_type
    return "<span class='none_text'>Not specified</span>".html_safe if model_type.nil?
    h(model_type.title)
  end

  def model_format_text model_format
    return "<span class='none_text'>Not specified</span>".html_safe if model_format.nil?
    h(model_format.title)
  end
  
  def authorised_models projects=nil
    authorised_assets(Model,projects)
  end

  def cytoscapeweb_supported? model
      model.contains_xgmml?
  end


  def allow_model_comparison model,displayed_model,user=User.current_user
    return false unless model.is_a?(Model)
    return false unless model.can_download?(user)
    return false unless displayed_model.contains_sbml?
    return false unless model.versions.select{|v| v.contains_sbml?}.count > 1
    true
  end

  def compare_model_version_selection versioned_model, displayed_resource_version
    versions=versioned_model.versions.reverse
    disabled=versions.size==1
    options=""
    versions.each do |v|
      if (v.version==displayed_resource_version.version || !v.contains_sbml?)
        options << "<option value='' disabled"
      else
        compare_path = compare_versions_model_path(versioned_model,:version=>displayed_resource_version.version,:other_version=>v.version)
        options << "<option value='#{compare_path}'"
      end

      options << " selected='selected'" if v.version==displayed_resource_version.version
      text = "#{v.version.to_s} #{versioned_model.describe_version(v.version)}"
      options << "> #{text} </option>"
    end
    select_tag(:compare_versions,
               options.html_safe,
               :disabled=>disabled,
               :onchange=>"showCompareVersions($('compare_versions_form'));"
    ) + "<form id='compare_versions_form' onsubmit='showCompareVersions(this); return false;'></form>".html_safe
  end

end
