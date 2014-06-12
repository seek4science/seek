module ModelsHelper

  JWS_ERROR_TO_PANEL_NAMES={
    "reaction" => "Reactions",
    "kinetics" => "Rate equations",
    "initVal"=>"Initial values",
    "parameters"=>"Parameter values",
    "functions"=>"Functions",
    "assRules"=>"Assignment rules",
    "events"=>"Events",
    "reacsAnnoErrors"=>"Annotations for processes",
    "speciesAnnoErrors"=>"Annotations for species"
  }
  
  JWS_ERROR_TO_PREFIX={
    "reaction" => "reactions",
    "kinetics" => "equations",
    "initVal"=>"initial",
    "parameters"=>"parameters",
    "functions"=>"functions",
    "assRules"=>"assignments",
    "events"=>"events",
    "reacsAnnoErrors"=>"annotated_reactions",
    "speciesAnnoErrors"=>"annotated_species"
  }

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

  def jws_annotator_hidden_fields params_hash
    required_params=["assignmentRules", "annotationsReactions", "annotationsSpecies", "modelname", "parameterset", "kinetics", "functions", "initVal", "reaction", "events", "steadystateanalysis", "plotGraphPanel", "plotKineticsPanel"]
    required_params.collect do |param|
      value = params_hash[param] || ""
      html=hidden_field_tag(param, "")
      #using javascript to decode the escaped strings (like \\n) as the URI.decode in ruby doesn't do this.
      html+="<script type='text/javascript'>$('#{param}').value=decodeURI('#{value}');</script>".html_safe
      html
    end.join(" ")
  end
  
  def jws_key_to_text key
    JWS_ERROR_TO_PANEL_NAMES[key]
  end
  
  def jws_key_to_prefix key
    JWS_ERROR_TO_PREFIX[key]  
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
