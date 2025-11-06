module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Person
      class Person < Thing
        PERSON_PROFILE = 'https://bioschemas.org/profiles/Person/0.2-DRAFT-2019_07_19/'.freeze

        associated_items member_of: :projects,
                         works_for: :institutions

        schema_mappings first_name: :givenName,
                        last_name: :familyName,
                        image: :image,
                        member_of: :memberOf,
                        orcid_identifier: :orcid,
                        works_for: :worksFor

        def conformance
          PERSON_PROFILE
        end

        def orcid_identifier
          return unless orcid.present?

          { '@id' => orcid }
        end

        def url
          web_page.blank? ? identifier : web_page
        end
      end
    end
  end
end
