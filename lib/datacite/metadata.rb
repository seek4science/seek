require_relative 'metadata_builder'

module DataCite
  class Metadata < Hash

    def initialize(hash)
      super.merge!(hash)
    end

    def build
      DataCite::MetadataBuilder.new(self).build
    end

    def to_s
      build.to_s
    end

  end
end
