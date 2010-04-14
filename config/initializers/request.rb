
module ActionController
  class AbstractRequest < ActionController::Request
    def self.relative_url_root=(path)
      ActionController::Base.relative_url_root=(path)
    end
    def self.relative_url_root
      ActionController::Base.relative_url_root
    end
  end
end

class ActionController::Request
  def relative_url_root
    ActionController::Base.relative_url_root.to_s
  end
end