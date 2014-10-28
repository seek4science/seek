module Seek
  module EnabledFeaturesFilter
    FEATURES = [:models,:biosamples,:organisms,:events,:documentation, :workflows, :programmes, :assays, :publications]

    def feature_enabled? feature
      feature=feature.to_s
      if Seek::Config.send("#{feature}_enabled")
        true
      else
        flash[:error] = "#{feature.capitalize} are disabled"
        redirect_to main_app.root_path
        false
      end
    end

    FEATURES.each do |feature|
      define_method("#{feature.to_s}_enabled?") do
        feature_enabled? feature
      end
    end

  end
end