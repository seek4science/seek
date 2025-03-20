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

  def allow_model_comparison(displayed_version_model, other_version_model, user = User.current_user)
    return false if (displayed_version_model.version == other_version_model.version) ||
                    !displayed_version_model.contains_sbml?
    parent = displayed_version_model.parent
    return false unless parent.is_a?(Model) && parent.can_download?(user) && other_version_model.contains_sbml?
    return false unless parent.versions.count(&:contains_sbml?) > 1
    true
  end

  def show_jws_simulate?
    Seek::Config.jws_enabled && @model.can_download? && @display_model.is_jws_supported?
  end

  def jws_online_logo
    image(:jws_online_logo, style: 'background-color:black;padding:1em;', class: 'img-responsive')
  end

  def show_copasi_button?
    Seek::Config.copasi_enabled && @display_model.is_copasi_supported? && @display_model.is_downloadable? && @display_model.can_download?(current_user)
  end

  def show_morpheus_button?
    Seek::Config.morpheus_enabled && (@display_model.policy.access_type == Policy::ALL_USERS) && @display_model.is_morpheus_supported?
  end

end
