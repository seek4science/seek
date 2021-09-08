module Seek
  module BioSchema
    module ResourceDecorators
      class CreativeWork < Thing
        associated_items producer: :projects,
                         part_of: :collections

        schema_mappings version: :version,
                        sd_publisher: :sdPublisher,
                        license: :license,
                        all_creators: :creator,
                        producer: :producer,
                        date_created: :dateCreated,
                        date_modified: :dateModified,
                        content_type: :encodingFormat,
                        subject_of: :subjectOf,
                        part_of: :isPartOf

        def content_type
          return unless resource.respond_to?(:content_blob) && resource.content_blob
          resource.content_blob.content_type
        end

        def license
          return unless resource.license
          Seek::License.find(resource.license)&.url
        end

        def subject_of
          return unless resource.respond_to?(:events)
          return [] if resource.events.empty?
          mini_definitions(resource.events)
        end
        
        def all_creators
          # This should be greatly improved but would rely on SEEK being changed
           others = other_creators&.split(',')&.collect(&:strip)&.compact || []
           others = others.collect { |name| { "@type": 'Person', "name": name } }
          all = (mini_definitions(creators) || []) + others
          return if all.empty?
          all
        end

        def sd_publisher
          sdp = { :@type => 'Organization',
                  :@id => Seek::Config.site_base_host,
                  :name => Seek::Config.project_name,
                  :url => Seek::Config.site_base_host
                }
          sdp
        end
        
      end
    end
  end
end
