module Ga4gh
  module Trs
    module V2
      class ToolSerializer < ActiveModel::Serializer
        include Seek::Util.routes

        attributes :id, :url, :name, :description, :organization, :toolclass
        has_many :versions

        def url
          workflow_url(object.id)
        end
      end
    end
  end
end
