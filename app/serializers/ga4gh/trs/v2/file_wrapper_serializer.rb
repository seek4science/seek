module Ga4gh
  module Trs
    module V2
      class FileWrapperSerializer < ActiveModel::Serializer
        attributes :content, :checksum, :url
      end
    end
  end
end
