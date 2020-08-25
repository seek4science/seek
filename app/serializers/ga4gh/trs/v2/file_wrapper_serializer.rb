module Ga4gh
module Trs
    module V2
      class FileWrapperSerializer < ActiveModel::Serializer
        attributes :content, :checksums, :url
      end
    end
  end
end