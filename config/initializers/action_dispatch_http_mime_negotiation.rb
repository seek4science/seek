# Monkeypatch because Rails doesn't seem to be behaving as expected.
# In routes.rb, the git routes are scoped with "format: false", so Rails should disregard the extension
# (e.g. /git/1/blob/my_file.yml) when determining the response format.
# However this results in an UnknownFormat error when trying to load the HTML view, as Rails still seems to be
# looking for an e.g. application/yaml view.
# You can fix this by adding { defaults: { format: :html } }, but then it is not possible to request JSON,
# even with an explicit `Accept: application/json` header!
#
# Inspired by GitLab's change:
# https://gitlab.com/gitlab-org/gitlab/-/blob/7a0c278e/config/initializers/action_dispatch_http_mime_negotiation.rb
# -Finn

module ActionDispatch
  module Http
    module MimeNegotiation
      alias original_format_from_path_extension format_from_path_extension

      def format_from_path_extension
        clz = controller_class
        if clz != ActionDispatch::Request::PASS_NOT_FOUND && clz&.ignore_format_from_extension
          nil
        else
          original_format_from_path_extension
        end
      end
    end
  end
end

module ActionController
  class Base
    def self.ignore_format_from_extension
      false
    end
  end
end
