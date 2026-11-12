module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Publication, described as a ScholarlyArticle
      class Publication < CreativeWork
        schema_mappings authors: :author,
                        publisher_organization: :publisher

        def schema_type
          'ScholarlyArticle'
        end

        # The authors in order. Those registered in SEEK are identified by their profile, the others by their name.
        def authors
          authors = parent_resource.publication_authors.map do |author|
            if author.person
              Seek::BioSchema::ResourceDecorators::Factory.instance.get(author.person).mini_definition
            else
              { '@type' => 'Person', '@id' => "##{ROCrate::Entity.format_id(author.full_name)}",
                'name' => author.full_name.strip }
            end
          end
          authors.presence
        end

        # The authors are given as the author, rather than also as the creator
        def all_creators; end

        # The DOI and the PubMed ID, as URLs
        def doi
          identifiers = [parent_resource.doi_uri, parent_resource.pubmed_uri].compact
          identifiers.presence
        end

        def date_published
          parent_resource.published_date&.iso8601
        end

        # The journal it was published in, along with any collections it belongs to
        def part_of
          parts = super || []
          parts += [{ '@type' => 'Periodical', 'name' => parent_resource.journal }] if parent_resource.journal.present?
          parts
        end

        # The licence is held by the publication rather than its versions
        def license
          return unless parent_resource.license

          Seek::License.find(parent_resource.license)&.url
        end

        def publisher_organization
          return if parent_resource.publisher.blank?

          { '@type' => 'Organization', 'name' => parent_resource.publisher }
        end
      end
    end
  end
end
