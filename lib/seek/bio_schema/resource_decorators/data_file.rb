module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a DataFile
      class DataFile < CreativeWork
        include ActionView::Helpers::NumberHelper

        
        schema_mappings distribution: :distribution

        DATASET_PROFILE = 'https://bioschemas.org/profiles/Dataset/1.0-RELEASE'.freeze

        def description
          description = resource.description&.truncate(4999)
          description = 'Description not specified' if description.blank?
          description.ljust(50, '.')
        end

        def distribution
          return unless resource.content_blob
          return if resource.content_blob.show_as_external_link?
          blob = resource.content_blob
          data = {
            '@type': 'DataDownload',
            'contentSize': number_to_human_size(blob.file_size),
            'contentUrl': resource_url([resource, blob], action: :download, strip_version: true),
            'encodingFormat': blob.content_type,
            'name': blob.original_filename
          }
          data['license'] = license if license
          data
        end

        def url
          if resource.content_blob && resource.content_blob.show_as_external_link?
            resource.content_blob.try(:url)
          else
            super
          end
        end

        def schema_type
          'Dataset'
        end

        def conformance
          DATASET_PROFILE
        end
      end
    end
  end
end
