module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a DataFile
      class DataFile < BaseDecorator

        include ActionView::Helpers::NumberHelper
        include Rails.application.routes.url_helpers

        associated_items creator: :creators

        def url
          rdf_resource
        end

        def doi
          if resource.doi
            "https://doi.org/#{resource.doi}"
          end
        end

        def distribution
          if resource.can_download?
            blob = resource.content_blob
            data = {'@type'=>'@DataDownload'}
            data['contentSize']=number_to_human_size(blob.file_size)
            data['contentUrl']=polymorphic_url([resource, blob], action: :download, host: Seek::Config.site_base_host)
            data['license'] = license if license
            data['encodingFormat'] = blob.content_type
            data['name'] = blob.original_filename
            data
          end


        end

        def license
          if resource.license
            license = Seek::License.find(resource.license)
            if license
              license.url
            end
          end
        end

        def schema_type
          'DataSet'
        end
      end
    end
  end
end
