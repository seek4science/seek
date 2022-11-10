module Seek
  module BioSchema
    module ResourceDecorators
      class Dataset < CreativeWork
        include ActionView::Helpers::NumberHelper

        schema_mappings distribution: :distribution

        DATASET_PROFILE = 'https://bioschemas.org/profiles/Dataset/0.3-RELEASE-2019_06_14/'.freeze

        def resource_url(resource, opts = {})
          polymorphic_url(resource.name, opts)
        end

        def distribution
          {
            '@type': 'DataDownload',
            'contentSize': number_to_human_size(File.size(resource.file)),
            'contentUrl': polymorphic_url(resource.name, format: :jsonld),
            "encodingFormat": "application/ld+json",
            'name': resource.file_name
          }
        end

        def schema_type
          'Dataset'
        end

        def conformance
          DATASET_PROFILE
        end

        def all_creators
          [DataCatalogMockModel.new.provider]
        end
      end
    end
  end
end
