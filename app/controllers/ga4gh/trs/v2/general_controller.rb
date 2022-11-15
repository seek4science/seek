module Ga4gh
  module Trs
    module V2
      class GeneralController < TrsBaseController
        def service_info
          respond_with({
              "contactUrl": "mailto:#{Seek::Config.support_email_address}",
              #"createdAt": "2019-06-04T12:58:19Z",
              "description": "TRS API endpoint for #{Seek::Config.instance_name}",
              "documentationUrl": "https://editor.swagger.io/?url=https://raw.githubusercontent.com/ga4gh/tool-registry-service-schemas/release/v2.0.1/openapi/openapi.yaml",
              "environment": Rails.env,
              "id": application_id,
              "name": Seek::Config.instance_name,
              "organization": {
                  "name": Seek::Config.instance_admins_name,
                  "url": Seek::Config.instance_admins_link
              },
              "type": {
                  "artifact": "trs",
                  "group": "org.ga4gh",
                  "version": "2.0.1"
              },
              #"updatedAt": "2019-06-04T12:58:19Z",
              "version": Seek::Version::APP_VERSION.to_s
          }.to_json)
        end

        def tool_classes
          respond_with([ToolClass::WORKFLOW], adapter: :attributes, root: nil) # I have no idea why this needs to be nil instead of '' - Finn
        end

        def organizations
          respond_with(Project.pluck(:title), adapter: :attributes)
        end

        private

        def application_id
          a = URI(Seek::Config.site_base_host).host.split('.').reverse.join('.')
          a += Rails.application.config.relative_url_root.split('/').join('.') if Rails.application.config.relative_url_root
          a
        rescue
          'misc-seek-deployment'
        end
      end
    end
  end
end
