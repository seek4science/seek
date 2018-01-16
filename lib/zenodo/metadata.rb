require 'datacite/metadata'

module Zenodo
  class Metadata < Hash

    REQUIRED_FIELDS = [:upload_type, :publication_date, :title, :creators, :description, :access_right]

    def initialize(hash)
      merge!(hash)
      self
    end

    def build
      validate
      self
    end

    def to_s
      build.to_json
    end

    def validate
      REQUIRED_FIELDS.each do |property|
        unless keys.include?(property) && !fetch(property).blank?
          raise MissingMetadataException.new("Required field: '#{property}' is missing")
        end
      end
      fetch(:creators).each do |creator|
        unless creator[:name]
          raise MissingMetadataException.new("Creator missing name: #{creator.inspect}")
        end
      end

      true
    end

  end

  class MissingMetadataException < Exception; end
end
