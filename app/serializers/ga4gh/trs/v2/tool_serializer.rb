module Ga4gh
  module Trs
    module V2
      class ToolSerializer < ActiveModel::Serializer
        include Rails.application.routes.url_helpers

        attributes :id, :url, :name
        has_many :versions

        def url
          workflow_url(object.id, host: Seek::Config.site_base_host)
        end
      end
    end
  end
end