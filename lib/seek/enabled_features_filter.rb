module Seek
  module EnabledFeaturesFilter
    FEATURES = %i[assays biosamples documentation events models
                  nels openbis organisms human_diseases programmes publications samples
                  studies investigations documents workflows collections observed_variables 
									observed_variable_sets project_single_page isa_json_compliance
                  data_files sops presentations file_templates placeholders].freeze

    def feature_enabled?(feature)
      feature = feature.to_s
      if Seek::Config.send("#{feature}_enabled")
        true
      else
        error = "#{feature.humanize} are disabled"
        respond_to do |format|
          format.html do
            if request.xhr?
              render html: "<div class=\"alert alert-danger\">#{error}</div>".html_safe, status: :unprocessable_entity
            else
              flash[:error] = error
              redirect_to main_app.root_path
            end
          end
          format.xml { render xml: "<error>#{error}</error>", status: :unprocessable_entity }
          format.json do
            render json: { title: error }, status: :unprocessable_entity
          end
        end

        false
      end
    end

    FEATURES.each do |feature|
      define_method("#{feature}_enabled?") do
        feature_enabled? feature
      end
    end
  end
end
