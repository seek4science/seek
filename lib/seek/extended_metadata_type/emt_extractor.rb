require 'json-schema'
# singleton class for extracting Extended Metadata Type and their attributes from json files
module Seek
  module ExtendedMetadataType
    module EMTExtractor
      def self.extract_extended_metadata_type(filename)
        file = File.read(filename)

        #todo check if the json file is valid later
        #res = check_json_file(file)
        #raise res if res.present?

        data_hash = JSON.parse(file)

        puts "**********************************"
        puts ":data_hash: #{data_hash}"
        puts "**********************************"

        begin
          create_extended_metadata_type_from_json(data_hash)
        rescue StandardError => e
          puts "Error: #{e.message}"
          raise e
        end

      end

      def self.create_extended_metadata_type_from_json(data)
        emt = ::ExtendedMetadataType.create(
          title: data['title'],
          supported_type: data['supported_type'],
          enabled: data['enabled']
        )

        data['attributes'].each do |attr|
          sample_attribute_type = SampleAttributeType.find_by(title: attr['type'])
          sample_controlled_vocab = SampleControlledVocab.find(attr['ID']) if sample_attribute_type&.controlled_vocab?
          linked_extended_metadata_type = ::ExtendedMetadataType.find(attr['ID']) if sample_attribute_type&.linked_extended_metadata_or_multi?


          emt.extended_metadata_attributes.build(
            title: attr['title'],
            label: attr['label'],
            description: attr['description'],
            sample_attribute_type: sample_attribute_type,
            sample_controlled_vocab: sample_controlled_vocab,
            linked_extended_metadata_type: linked_extended_metadata_type,
            required: attr['required'].present? ? attr['required'] : false
          )
        end

        if emt.save
          puts "ExtendedMetadataType '#{emt.title}' created successfully."
        else
          error_message = "Failed to create ExtendedMetadataType: #{emt.errors.full_messages.join(', ')}"
          puts error_message
          raise StandardError, error_message
        end
      end
    end
  end
end