require_relative 'metadata_builder'

module DataCite
  class Metadata < Hash
    REQUIRED_FIELDS = %i[title identifier publisher year creators resource_type].freeze
    GENERAL_TYPES = %w(Audiovisual Collection DataPaper Dataset Event Image InteractiveResource Model PhysicalObject
                       Service Software Sound Text Workflow Other).freeze

    def initialize(hash)
      super.merge!(hash)
    end

    def build
      validate
      DataCite::MetadataBuilder.new(self).build
    end

    def to_s
      build.to_s
    end

    def validate
      REQUIRED_FIELDS.each do |property|
        raise MissingMetadataException, "Required field: '#{property}' is missing" unless keys.include?(property)
      end
      self[:creators].each do |creator|
        unless creator.respond_to?(:first_name) && !creator.first_name.blank?
          raise MissingMetadataException, "Creator missing first name: #{creator.inspect}"
        end
        unless creator.respond_to?(:last_name) && !creator.last_name.blank?
          raise MissingMetadataException, "Creator missing last name: #{creator.inspect}"
        end
      end
      if !(self[:resource_type].length == 2 && self[:resource_type].all?(&:present?))
        raise InvalidMetadataException, "'resource_type' should have 2 elements: type and general type"
      elsif !GENERAL_TYPES.include?(self[:resource_type][1])
        raise InvalidMetadataException, "General resource type should be one of: #{GENERAL_TYPES.join(', ')}"
      end

      true
    end
  end

  class MissingMetadataException < RuntimeError; end
  class InvalidMetadataException < RuntimeError; end
end
