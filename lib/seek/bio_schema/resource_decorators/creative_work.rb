module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Event
      class CreativeWork < Thing
        associated_items producer: :projects

        schema_mappings license: :license,
                        all_creators: :creator,
                        producer: :producer,
                        date_created: :dateCreated,
                        date_modified: :dateModified,
                        content_type: :encodingFormat,
                        subject_of: :subjectOf,
                        provider: :sdPublisher,
                        previous_version_url: :isBasedOn

        def content_type
          return unless respond_to?(:content_blob) && content_blob
          content_blob.content_type
        end

        def license
          return unless resource.license
          Seek::License.find(resource.license)&.url
        end

        def all_creators
          others = other_creators&.split(',')&.collect(&:strip)&.compact || []
          others = others.collect { |name| { "@type": 'Person', "@id": "##{ROCrate::Entity.format_id(name)}", "name": name } }
          all = (mini_definitions(creators) || []) + others
          return if all.empty?
          all
        end

        def previous_version_url
          return unless respond_to?(:previous_version) && resource.previous_version
          resource_url(resource.previous_version)
        end
      end
    end
  end
end
