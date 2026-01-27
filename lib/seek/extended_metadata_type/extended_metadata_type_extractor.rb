require 'json-schema'
# singleton class for extracting Extended Metadata Type and their attributes from json files
module Seek
  module ExtendedMetadataType
    module ExtendedMetadataTypeExtractor
      class ValidationError < StandardError; end;

      SCHEMA_PATH = Rails.root.join('lib', 'seek', 'extended_metadata_type', 'extended_metadata_type_schema.json').freeze

      def self.extract_extended_metadata_type(file)

        begin
          data_hash = JSON.parse(file.read)
        rescue JSON::ParserError => e
          raise JSON::ParserError, "Failed to parse JSON file: #{e.message}"
        end

        valid_emt_json?(data_hash)

        create_extended_metadata_type_from_json(data_hash)

      end


      def self.valid_emt_json?(json)

        raise StandardError, "The schema file is not readable!" unless File.readable?(SCHEMA_PATH)

        schema = JSON.parse(File.read(SCHEMA_PATH))
        errors = JSON::Validator.fully_validate(schema, json)

        raise ValidationError, "Invalid JSON file: #{errors.join(', ')}" if errors.present?

      end

      def self.validate_attribute_type(type)
        unless SampleAttributeType.where(title: type).present?
          raise ValidationError, "The attribute type '#{type}' does not exist."
        end
      end

      def self.create_extended_metadata_type_from_json(data)
        emt = ::ExtendedMetadataType.create(
          title: data['title'],
          supported_type: data['supported_type'],
          enabled: data['enabled']
        )

        data['attributes'].each do |attr|

          validate_attribute_type(attr['type'])

          sample_attribute_type = SampleAttributeType.find_by(title: attr['type'])
          sample_controlled_vocab = SampleControlledVocab.find(attr['ID']) if sample_attribute_type &.controlled_vocab?
          linked_extended_metadata_type = ::ExtendedMetadataType.find(attr['ID']) if sample_attribute_type&.linked_extended_metadata_or_multi?


          emt.extended_metadata_attributes.build(
            title: attr['title'],
            label: attr['label'].present? ? attr['label'] : nil,
            description: attr['description'].present? ? attr['description'] : nil,
            sample_attribute_type: sample_attribute_type,
            sample_controlled_vocab: sample_controlled_vocab,
            linked_extended_metadata_type: linked_extended_metadata_type,
            required: attr.key?('required') ? attr['required'] : false,
            allow_cv_free_text: attr.key?('allow_cv_free_text') ? attr['allow_cv_free_text'] : false,
            pid: attr['pid'].present? ? attr['pid'] : nil
          )
        end
        emt
      end
    end
  end
end
