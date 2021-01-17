module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Event
      class CreativeWork < Thing
        associated_items provider: :projects,
                         creator: :creators,
                         subject_of: :events

        schema_mappings license: :license,
                        creator: :creator,
                        provider: :provider,
                        created_at: :dateCreated,
                        updated_at: :dateModified,
                        content_type: :encodingFormat,
                        subject_of: :subjectOf

        def content_type
          return unless resource.respond_to?(:content_blob) && resource.content_blob
          resource.content_blob.content_type
        end

        def license
          return unless resource.license
          Seek::License.find(resource.license)&.url
        end
      end
    end
  end
end
