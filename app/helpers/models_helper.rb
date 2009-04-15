module ModelsHelper

  def model_environment_text model
    model.recommended_environment ? h(model.recommended_environment.title) : "<span class='none_text'>Unknown</span>" 
  end

  def model_jws_online_compatible? model
    return !model.recommended_environment.nil? && model.recommended_environment.title.downcase=="jws online"
  end

  def execute_model_label
    icon_filename=method_to_icon_filename("execute")

    return '<span class="icon">' + image_tag(icon_filename,:alt=>"Simulate",:title=>"Simulate") + ' Simulate model</span>';
  end

end
