module Seek
  class ApplicationConfiguration

    def self.default_page controller
      init_pagination_settings
      @@pagination_settings[controller.to_s]["index"]
    end

    def self.init_pagination_settings
      @@pagination_settings ||= nil
      
      unless @@pagination_settings
        configpath=File.join(RAILS_ROOT, PAGINATION_CONFIG_FILE)
        @@pagination_settings=YAML::load_file(configpath)
      end
    end

  end
end