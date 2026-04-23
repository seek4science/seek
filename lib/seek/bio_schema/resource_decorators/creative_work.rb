module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a CreativeWork
      class CreativeWork < Thing
        associated_items producer: :projects,
                         part_of: :collections,
                         subject_of: :events

        schema_mappings version: :version,
                        license: :license,
                        all_creators: :creator,
                        producer: :producer,
                        created_at: :dateCreated,
                        updated_at: :dateModified,
                        content_type: :encodingFormat,
                        subject_of: :subjectOf,
                        part_of: :isPartOf,
                        doi: :identifier,
                        previous_version_url: :isBasedOn,
                        date_published: :datePublished,
                        publications: :citation



        def doi
          "https://doi.org/#{resource.doi}" if resource.try(:doi).present?
        end

        # If a DOI has been minted, use the date of minting as the publication date
        def date_published
          return unless parent_resource.supports_doi? && parent_resource.has_doi?
          return unless AssetDoiLog.was_doi_minted_for?(parent_resource.class.name, parent_resource.id, resource.version)

          AssetDoiLog.minted.where(asset: parent_resource, asset_version: resource.version).order(:created_at).last&.created_at&.iso8601
        end

        def content_type
          return unless resource.respond_to?(:content_blob) && resource.content_blob

          resource.content_blob.content_type
        end

        def license
          return unless resource.license

          Seek::License.find(resource.license)&.url
        end

        def all_creators
          # This should be greatly improved but would rely on SEEK being changed
          others = other_creators&.split(',')&.collect(&:strip)&.compact || []
          others = others.collect { |name| { "@type": 'Person',"@id": "##{ROCrate::Entity.format_id(name)}", "name": name } }
          all = mini_definitions(assets_creators) + others
          return if all.empty?

          all
        end

        def previous_version_url
          return unless respond_to?(:previous_version) && resource.previous_version

          resource_url(resource.previous_version)
        end

        def publications
          return unless parent_resource.respond_to?(:publications)

          parent_resource.publications.map do |publication|
            {
              '@type' => 'ScholarlyArticle',
              '@id' => publication.rdf_resource.to_s,
              'name' => publication.title
            }
          end
        end

      end
    end
  end
end
