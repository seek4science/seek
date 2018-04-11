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
        { DataFile => :Data,
          Model => :Model,
          Sop => :SOP,
          Person => :Person,
          Organism => :Organism,
          Project => :Project,
          Programme => :Programme,
          Study => :Study,
          Investigation => :Investigation,
          Publication => :Publication,
          Strain => :Strain,
          Compound => :Compound,
          StudiedFactor => :Factors_studied,
          Sample => :Data_sample}
      end

      # this is the class fragment according to the measured item title
      def self.measured_item_entity_fragment(title)
        defined_measures_item_types[title]
      end

      # FIXME: I think I would prefer these as actual attributes on the MeasureItem object, making it easier to configure new ones in the future
      # predefined mappings between the measured item name and their class
      def self.defined_measures_item_types
        {
          'acidity/PH' => :pH,
          'gas flow rate' => :Gas_flow,
          'dry biomass concentration' => :Dry_biomass,
          'dilution rate' => nil, # problem with: 'Growth_rate/Dilution_rate,
          'temperature' => :Temperature,
          'pressure' => :Pressure,
          'specific concentration' => :Specific_concentration,
          'concentration' => :Concentration,
          'buffer' => :Buffer,
          'time' => :Time_series,
          'growth medium' => :Growth_medium_composition,
          'stiring rate' => nil, # missing from ontology
          'optical density 600 nm' => :Optical_density_600,
          'glucose pulse' => nil, # missing from ontology
        }
      end
    end
  end
end
