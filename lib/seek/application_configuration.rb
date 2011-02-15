module Seek
  class ApplicationConfiguration

    @@pagination_settings ||= nil

    def self.default_page controller
      unless @@pagination_settings
        configpath           =File.join(RAILS_ROOT, "config/paginate.yml")
        @@pagination_settings=YAML::load_file(configpath)
      end
      @@pagination_settings[controller.to_s]["index"]
    end

  end
end