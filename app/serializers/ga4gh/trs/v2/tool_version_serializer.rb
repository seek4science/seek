module Ga4gh
  module Trs
    module V2
      class ToolVersionSerializer < ActiveModel::Serializer
        include Rails.application.routes.url_helpers

        attributes :id, :url, :name, :author, :descriptor_type

        def url
          workflow_url(object.tool_id, version: object.id, host: Seek::Config.site_base_host)
        end
      end
    end
  end
end
