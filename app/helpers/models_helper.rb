module ModelsHelper
  def model_environment_text(model)
    environment = model.recommended_environment
    environment ? environment.title : "<span class='none_text'>Not specified</span>".html_safe
  end

  def execute_model_label
    icon_filename = icon_filename_for_key('execute')
    html = '<span class="icon">' + image_tag(icon_filename, alt: 'Run', title: 'Run') + ' Run model</span>'
    html.html_safe
  end

  def model_type_text(model_type)
    model_type ? model_type.title : "<span class='none_text'>Not specified</span>".html_safe
  end

  def model_format_text(model_format)
    model_format ? model_format.title : "<span class='none_text'>Not specified</span>".html_safe
  end

  def authorised_models(projects = nil)
    authorised_assets(Model, projects)
  end

  def cytoscapeweb_supported?(model)
    model.contains_xgmml?
  end

  def allow_model_comparison(model, displayed_model, user = User.current_user)
    return false unless model.is_a?(Model) && model.can_download?(user) && displayed_model.contains_sbml?
    return false unless model.versions.select { |version| version.contains_sbml? }.count > 1
    true
  end

  def compare_model_version_selection(versioned_model, displayed_resource_version)
    versions = versioned_model.versions.reverse
    disabled = versions.size == 1
    options = ''
    versions.each do |model_version|
      options << generate_model_version_comparison_option(displayed_resource_version, model_version, versioned_model)
    end
    compare_model_version_select_tag(disabled, options)
  end

  def compare_model_version_select_tag(disabled, options)
    select_tag(:compare_versions,
               options.html_safe,
               disabled: disabled,
               onchange: "showCompareVersions($('compare_versions_form'));"
    ) + "<form id='compare_versions_form' onsubmit='showCompareVersions(this); return false;'></form>".html_safe
  end

  def generate_model_version_comparison_option(displayed_model_version, other_model_version, versioned_model)
    options = ''
    other_version = other_model_version.version
    displayed_version = displayed_model_version.version
    if other_version == displayed_version || !other_model_version.contains_sbml?
      options << "<option value='' disabled"
    else
      compare_path = compare_versions_model_path(versioned_model, version: displayed_version, other_version: other_version)
      options << "<option value='#{compare_path}'"
    end

    options << " selected='selected'" if other_version == displayed_version
    text = "#{other_version} #{versioned_model.describe_version(other_version)}"
    options << "> #{text} </option>"
    options
  end

  def show_jws_simulate?
    Seek::Config.jws_enabled && @model.can_download? && @display_model.is_jws_supported?
  end
end
