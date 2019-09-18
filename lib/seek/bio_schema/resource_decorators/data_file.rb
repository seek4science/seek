module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a DataFile
      class DataFile < CreativeWork
        include ActionView::Helpers::NumberHelper

        schema_mappings doi: :identifier,
                        distribution: :distribution

        def doi
          "https://doi.org/#{resource.doi}" if resource.doi
        end

        def distribution
          return unless resource.can_download?
          blob = resource.content_blob
          data = {
            '@type': 'DataDownload',
            'contentSize': number_to_human_size(blob.file_size),
            'contentUrl': polymorphic_url([resource, blob], action: :download, host: Seek::Config.site_base_host),
            'encodingFormat': blob.content_type,
            'name': blob.original_filename
          }
          data['license'] = license if license
          data
        end

        def schema_type
          'DataSet'
        end
      end
    end
  end
end
