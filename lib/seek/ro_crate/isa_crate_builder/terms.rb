module Seek
  module RoCrate
    class ISACrateBuilder
      # The ISA level of each dataset: the additionalType value and the DefinedTerm describing it.
      module Terms
        # What the three ISA levels mean, written into the crate next to their JERM term IRIs so a
        # reader who does not know the ontology still sees a definition.
        ISA_TERM_DESCRIPTIONS = {
          'Investigation' => 'An ISA Investigation: the top-level container of a research project, ' \
                             'holding its studies.',
          'Study' => 'An ISA Study: a unit of research within an Investigation, grouping the assays ' \
                     'that share a design and subjects.',
          'Assay' => 'An ISA Assay: a measurement or analysis within a Study, with its samples, ' \
                     'protocols and data files.'
        }.freeze

        private

        # additionalType is a list: the IRI of the JERM ontology term, plus the bare name ("Investigation",
        # "Study" or "Assay"). ARC tools only recognise a Dataset as a study or an assay by that exact
        # string; with the JERM IRI alone they silently skip the entity, and an {"@id": ...} reference in
        # the list makes them reject the whole crate. So the IRI stays a plain string, and the term it
        # names is described by a DefinedTerm entity in the graph instead.
        def isa_type(crate, name)
          isa_term(crate, name)
          ["#{JERM}#{name}", name]
        end

        # One DefinedTerm per ISA level in use, identified by its JERM IRI.
        def isa_term(crate, name)
          @isa_terms ||= {}
          @isa_terms[name] ||= begin
            term = ::ROCrate::ContextualEntity.new(crate, "#{JERM}#{name}", '@type' => 'DefinedTerm')
            set(term, 'name' => name, 'description' => ISA_TERM_DESCRIPTIONS[name])
            crate.add_contextual_entity(term)
          end
        end
      end
    end
  end
end
