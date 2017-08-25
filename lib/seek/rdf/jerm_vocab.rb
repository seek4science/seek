module Seek
  module Rdf
    class JERMVocab < RDF::Vocabulary('http://jermontology.org/ontology/JERMOntology#')
      property :Data
      property :hasPart
      property :isPartOf
      property :External_supplier_ID
      property :NCBI_ID

      # returns the correct Class IRI according to the instance 'type' - or nil if its not recognised
      def self.for_type(type)
        defined_type = defined_types[type.class]
        return nil unless defined_type
        send(defined_type)
      end

      # private - predefined list of types and their JERM ontology class
      def self.defined_types
        { DataFile => :Data,
          Model => :Model,
          Sop => :SOP,
          Assay => :Assay,
          Person => :Person,
          Organism => :organism,
          Project => :Project,
          Programme => :Programme,
          Study => :Study,
          Investigation => :Investigation,
          Publication => :Publication,
          Strain => :strain,
          Compound => :compound }
      end

      private_class_method :defined_types
    end
  end
end
