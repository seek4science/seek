module Seek
  module EnabledFeaturesFilter
    def feature_enabled? feature
      feature=feature.to_s
      if Seek::Config.send("#{feature}_enabled")
        true
      else
        flash[:error] = "#{feature.capitalize} are disabled"
        redirect_to :root
        false
      end
    end

    def models_enabled?
      feature_enabled? :models
    end

    def biosamples_enabled?
      feature_enabled? :biosamples
    end

    def organisms_enabled?
      feature_enabled? :organisms
    end

    def events_enabled?
      feature_enabled? :events
    end
  end
end