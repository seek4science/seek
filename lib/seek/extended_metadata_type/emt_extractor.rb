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

        # Initialize a new ExtendedMetadataType with the title, supported_type, and enabled status from the JSON data
        emt = ::ExtendedMetadataType.create(title: data['title'], supported_type: data['supported_type'], enabled: data['enabled'])

        # Iterate over each attribute in the JSON data
        data['attributes'].each do |attr|
          # Create a new ExtendedMetadataAttribute for each attribute in the JSON data
          emt.extended_metadata_attributes.build(
            title: attr['title'],
            label: attr['label'],
            description: attr['description'],
            sample_attribute_type: SampleAttributeType.where(title: attr['attribute_type']).first,
            required: attr['required']
          )
        end

        # Attempt to save the ExtendedMetadataType along with its associated attributes
        puts "_______________________________________________"
        if emt.save
          puts "ExtendedMetadataType '#{emt.title}' created successfully."
        else
          error_message = "Failed to create ExtendedMetadataType: #{emt.errors.full_messages.join(', ')}"
          puts error_message
          raise StandardError, error_message
        end
        puts "_______________________________________________"
      end




    end
  end
end