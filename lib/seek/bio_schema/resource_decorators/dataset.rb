module Seek
  module BioSchema
    module ResourceDecorators
      class Dataset < CreativeWork
        include ActionView::Helpers::NumberHelper

        schema_mappings distribution: :distribution,
                        data_catalog: :includedInDataCatalog

        DATASET_PROFILE = 'https://bioschemas.org/profiles/Dataset/0.3-RELEASE-2019_06_14/'.freeze

        def resource_url(r, opts = {})
          super(r.model, opts) # For some reason delegation doesn't work here, so have to call `model` explicitly.
        end

        def distribution
          dump = resource.public_schema_ld_dump
          if dump.exists?
            {
              '@type': 'DataDownload',
              'contentSize': number_to_human_size(dump.size),
              'contentUrl': resource_url(resource, dump: true, format: :jsonld),
              "encodingFormat": "application/ld+json",
              'name': dump.file_name,
              'description': "A collection of public #{title} in #{Seek::Config.instance_name}, serialized as an array of JSON-LD objects conforming to Bioschemas profiles.",
              'dateModified': dump.date_modified.iso8601
            }
          end
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

        def data_catalog
          Factory.instance.get(DataCatalogMockModel.new).reference
        end

        def keywords
          []
        end
      end
    end
  end
end
