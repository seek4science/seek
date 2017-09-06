module Seek
  module Rdf
    class JERMVocab < RDF::Vocabulary('http://jermontology.org/ontology/JERMOntology#')
      # these are explicitly defined, to prevent the undercores being changed to camelCase
      property :External_supplier_ID
      property :NCBI_ID
      property :experimental_assay
      property :modelling_analysis
      property :SEEK_ID

      # returns the correct Class IRI according to the instance 'type' - or nil if its not recognised
      def self.for_type(type)
        return nil unless type.respond_to?(:rdf_class_entity)
        send(type.rdf_class_entity)
      end

      # predefined list of types and their JERM ontology class
      def self.defined_types
        { DataFile => :Data,
          Model => :Model,
          Sop => :SOP,
          Person => :Person,
          Organism => :organism,
          Project => :Project,
          Programme => :Programme,
          Study => :Study,
          Investigation => :Investigation,
          Publication => :Publication,
          Strain => :strain,
          Compound => :compound,
          StudiedFactor => :factor_studied}
      end
    end
  end
end
