module ModelsHelper

  JWS_PANEL_NAMES={
    "reacs" => "Reactions",
    "kinetics" => "Rate equations",
    "initVal"=>"Initial values",
    "parameters"=>"Parameter values",
    "functions"=>"Functions",
    "assRules"=>"Assignment rules",
    "events"=>"Events"
  }

  def model_environment_text model
    model.recommended_environment ? h(model.recommended_environment.title) : "<span class='none_text'>Unknown</span>" 
  end

  def model_jws_online_compatible? model
    return !model.recommended_environment.nil? && model.recommended_environment.title.downcase=="jws online"
  end

  def execute_model_label
    icon_filename=icon_filename_for_key("execute")

    return '<span class="icon">' + image_tag(icon_filename,:alt=>"Run",:title=>"Run") + ' Run model</span>';
  end

  def model_type_text model_type
    return "<span class='none_text'>Not specified</span>" if model_type.nil?
    return h(model_type.title)
  end

  def model_format_text model_format
    return "<span class='none_text'>Not specified</span>" if model_format.nil?
    return h(model_format.title)
  end
  
  def authorised_models
    models=Model.find(:all)
    Authorization.authorize_collection("show",models,current_user)
  end  
  
  def jws_supported? model
    builder = Seek::JWSModelBuilder.new
    builder.is_supported? model
  end
  
  def jws_key_to_text key
    return JWS_PANEL_NAMES[key]
  end

end
