require 'json-schema'
# singleton class for extracting Extended Metadata Type and their attributes from json files
module Seek
  module ExtendedMetadataType
    module EMTExtractor
      def self.extract_extended_metadata_type(file)

        begin
          data_hash = JSON.parse(file.read)
        rescue JSON::ParserError => e
          raise StandardError, "Failed to parse JSON file: #{e}"
        end


        begin
          valid_emt_json?(data_hash)
        rescue StandardError => e
          raise StandardError,  e
        end

        create_extended_metadata_type_from_json(data_hash)

      end


      def self.valid_emt_json?(json)
        schema_path = Rails.root.join('lib', 'seek', 'extended_metadata_type', 'extended_metadata_type_schema.json')
        raise StandardError, "The schema file is not readable!" unless File.readable?(schema_path)

        schema = JSON.parse(File.read(schema_path))
        errors = JSON::Validator.fully_validate(schema, json)

        raise StandardError, "Invalid JSON file: #{errors.join(', ')}" if errors.present?

      end

      def self.create_extended_metadata_type_from_json(data)
        @extended_metadata_type = ::ExtendedMetadataType.create(
          title: data['title'],
          supported_type: data['supported_type'],
          enabled: data['enabled']
        )

        data['attributes'].each do |attr|
          sample_attribute_type = SampleAttributeType.find_by(title: attr['type'])
          sample_controlled_vocab = SampleControlledVocab.find(attr['ID']) if sample_attribute_type&.controlled_vocab?
          linked_extended_metadata_type = ::ExtendedMetadataType.find(attr['ID']) if sample_attribute_type&.linked_extended_metadata_or_multi?


          @extended_metadata_type.extended_metadata_attributes.build(
            title: attr['title'],
            label: attr['label'].present? ? attr['label'] : nil,
            description: attr['description'].present? ? attr['description'] : nil,
            sample_attribute_type: sample_attribute_type,
            sample_controlled_vocab: sample_controlled_vocab,
            linked_extended_metadata_type: linked_extended_metadata_type,
            required: attr['required'].present? ? attr['required'] : false
          )
        end

        @extended_metadata_type.save!

      end


    end
  end
end