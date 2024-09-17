require 'json-schema'
# singleton class for extracting Extended Metadata Type and their attributes from json files
module Seek
  module ExtendedMetadataType
    module EMTExtractor
      def self.extract_extended_metadata_type(filename)

        clear

        `touch #{errorfile}`
        `touch #{emtfile}`

        file = File.read(filename)

        begin
          data_hash = JSON.parse(file)
        rescue JSON::ParserError => e
          write_result(errorfile,"Failed to parse JSON: #{e}")
        end


        res = valid_emt_json?(data_hash)

        write_result(errorfile,res) if res.present?


        begin
          create_extended_metadata_type_from_json(data_hash)
        rescue StandardError => e
          write_result(errorfile,"error(s): #{e}")
        end

      end

      def self.valid_emt_json?(json)
        definitions_path =
          File.join(Rails.root, 'lib', 'seek', 'extended_metadata_type', 'extended_metadata_type_schema.json')
        if File.readable?(definitions_path)
          schema= JSON.parse(File.read(definitions_path))
          errors = JSON::Validator.fully_validate(schema, json)
          #puts "errors: #{errors}"
        else
          errors = ['The schema file is not readable!']
        end
         errors.join("\n\n")
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
            label: attr['label'].present? ? attr['label'] : nil,
            description: attr['description'].present? ? attr['description'] : nil,
            sample_attribute_type: sample_attribute_type,
            sample_controlled_vocab: sample_controlled_vocab,
            linked_extended_metadata_type: linked_extended_metadata_type,
            required: attr['required'].present? ? attr['required'] : false
          )
        end

        if emt.save
          puts "ExtendedMetadataType '#{emt.title}' created successfully."
          write_result(emtfile,"#{emt.id}")
        else
          error_message = "Failed to create ExtendedMetadataType: #{emt.errors.full_messages.join(', ')}"
          puts error_message
          raise StandardError, error_message
        end
      end

      private

      def self.errorfile
        Rails.root.join(Seek::Config.append_filestore_path('emt_files'), 'result.error')
      end
      def self.emtfile
        Rails.root.join(Seek::Config.append_filestore_path('emt_files'), 'result.id')
      end

      def self.write_result(file, result)
        File.open(file, 'a') { |file| file.write("#{result}\n") }
      end

      def self.clear

        file_path = Rails.root.join('filestore', 'emt_files', 'result.id')
        File.delete(file_path) if File.exist?(file_path)

        file_path = Rails.root.join('filestore', 'emt_files', 'result.error')
        File.delete(file_path) if File.exist?(file_path)

      end

    end
  end
end