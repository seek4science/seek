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
    return false if model.version == displayed_model.version
    return false unless model.is_a?(Model) && model.can_download?(user) && displayed_model.contains_sbml?
    return false unless model.versions.select { |version| version.contains_sbml? }.count > 1
    true
  end

  def show_jws_simulate?
    Seek::Config.jws_enabled && @model.can_download? && @display_model.is_jws_supported?
  end
end
