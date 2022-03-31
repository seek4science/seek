module Rack
  class SettingsCache
    def initialize(app)
      @app = app
    end

    def call(env)
      Seek::Config.enable_cache!
      response = @app.call(env)
      Seek::Config.disable_cache!

      response
    end
  end
end
