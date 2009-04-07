module ModelsHelper

  def model_environment_text model
    model.recommended_environment ? h(model.recommended_environment.title) : "<span class='none_text'>Unknown</span>" 
  end

  def model_jws_online_compatible? model
    return !model.recommended_environment.nil? && model.recommended_environment.title.downcase=="jws online"
  end

  def get_jws_online_applet model
    
  end

end
