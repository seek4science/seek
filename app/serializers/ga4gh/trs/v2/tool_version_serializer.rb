module Ga4gh
module Trs
    module V2
      class ToolVersionSerializer < ActiveModel::Serializer
        attributes :id, :name, :authors, :descriptor_type
      end
    end
  end
end