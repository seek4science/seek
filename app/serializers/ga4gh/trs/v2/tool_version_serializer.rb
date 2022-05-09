module Ga4gh
  module Trs
    module V2
      class ToolVersionSerializer < ActiveModel::Serializer
        include Seek::Util.routes

        attributes :id, :url, :name, :author, :descriptor_type

        def url
          workflow_url(object.tool_id, version: object.id)
        end
      end
    end
  end
end
