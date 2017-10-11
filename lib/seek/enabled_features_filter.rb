module Seek
  module EnabledFeaturesFilter
    FEATURES = [:models, :biosamples, :organisms, :events, :documentation, :workflows, :programmes, :assays, :publications, :samples, :openbis]

    def feature_enabled?(feature)
      feature = feature.to_s
      if Seek::Config.send("#{feature}_enabled")
        true
      else
        respond_to do |format|
          format.html {
            flash[:error] = "#{feature.capitalize} are disabled"
            redirect_to main_app.root_path
          }
          format.xml { render text: '<error>'+"#{feature.capitalize} are disabled"+'</error>', status: :unprocessable_entity }
          format.json {
            errors = [{"title": "#{feature.capitalize} are disabled", "status": :unprocessable_entity}]
            render json: JSONAPI::Serializer.serialize_errors(errors), status: :unprocessable_entity
          }
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
