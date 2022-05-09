module Seek
  module Rdf
    class JERMVocab < RDF::Vocabulary('http://jermontology.org/ontology/JERMOntology#')
      # these are explicitly defined, to prevent the undercores being changed to camelCase
      property :NCBI_ID
      property :Experimental_assay
      property :Modelling_analysis
      property :seekID
      property :Factors_studied
      property :Gas_flow
      property :Specific_concentration
      property :Time_series
      property :Growth_medium_composition
      property :Optical_density_600
      property :Simulation_data
      property :Data_sample

      # returns the correct Class IRI according to the instance 'type' - or nil if its not recognised
      def self.for_type(type)
        return nil unless type.respond_to?(:rdf_class_entity)
        send(type.rdf_class_entity)
      end

      # predefined list of types and their JERM ontology class
      def self.defined_types
        {
          Assay => :Assay,
          DataFile => :Data,
          Model => :Model,
          Sop => :SOP,
          Person => :Person,
          Organism => :Organism,
          Project => :Project,
          Programme => :Programme,
          Study => :Study,
          Investigation => :Investigation,
          Publication => :Publication,
          Strain => :Strain
        }
      end

    end
  end
end
