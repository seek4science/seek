require 'datacite/metadata'

module Zenodo
  class Metadata < Hash

    REQUIRED_FIELDS = [:upload_type, :publication_date, :title, :creators, :description, :access_right]

    def initialize(hash)
      super.merge!(hash)
    end

    def build
      self[:creators] = self[:creators].map do |c|
        if c.is_a?(Person)
          { name: "#{c.last_name}, #{c.first_name}" }
        else
          c
        end
      end

      validate
      self
    end

    def to_s
      build.to_json
    end

    def validate
      REQUIRED_FIELDS.each do |property|
        unless keys.include?(property) && !self[property].blank?
          raise MissingMetadataException.new("Required field: '#{property}' is missing")
        end
      end
      self[:creators].each do |creator|
        unless creator[:name]
          raise MissingMetadataException.new("Creator missing name: #{creator.inspect}")
        end
      end

      true
    end

  end

  class MissingMetadataException < Exception; end
end
