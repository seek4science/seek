module Seek
  module RoCrate
    class ISACrateBuilder
      # Person entities and the creator references that point at them.
      module People
        private

        # The creators of a resource, or its contributor when none are recorded, as Person references.
        def creator_references(crate, resource)
          people = resource.creators.presence || [resource.contributor].compact
          people.map { |person| person_reference(crate, person) }
        end

        # One Person entity per person however many resources they created, identified by ORCID when
        # present and otherwise by a fragment of the person's SEEK id.
        def person_reference(crate, person)
          id = person.ro_crate_metadata['@id']
          @people ||= {}
          @people[id] ||= crate.add_contextual_entity(::ROCrate::Person.new(crate, id, person_properties(person)))
          @people[id].reference
        end

        # givenName is required; a person recorded without a first name falls back to the full name.
        def person_properties(person)
          { 'name' => person.name,
            'givenName' => person.first_name.presence || person.name,
            'familyName' => person.last_name.presence,
            'identifier' => person.ro_crate_metadata[:identifier] }.compact
        end
      end
    end
  end
end
