require 'datacite/metadata'

module Zenodo
  class Metadata

    REQUIRED_FIELDS = [:upload_type, :publication_date, :title, :creators, :description, :access_right]

    def self.from_datacite(datacite_metadata)
      hash = datacite_metadata
      hash[:doi] = hash[:identifier]
      hash[:publication_date] = Time.now
      hash[:creators] = hash[:creators].map { |c| { name: "#{c.last_name}, #{c.first_name}" } }
      (DataCite::Metadata::REQUIRED_FIELDS - Zenodo::Metadata::REQUIRED_FIELDS).each do |unused|
        hash.delete(unused)
      end
      new(hash)
    end

    def initialize(hash)
      super.merge!(hash)
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
        raise MissingMetadataException.new("Required field: '#{property}' is missing") unless keys.include?(property)
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
