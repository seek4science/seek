module Seek
  class ApplicationConfiguration

    def self.default_page controller
      Settings.index[controller.to_sym]
    end

  end
end