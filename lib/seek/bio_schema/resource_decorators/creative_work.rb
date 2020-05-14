module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Event
      class CreativeWork < Thing
        associated_items producer: :projects

        schema_mappings license: :license,
                        all_creators: :creator,
                        producer: :producer,
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

        def all_creators
          others = other_creators&.split(',')&.collect(&:strip)&.compact || []
          others = others.collect { |name| { "@type": 'Person', "name": name } }
          all = (mini_definitions(creators) || []) + others
          return if all.empty?
          all
        end
      end
    end
  end
end
