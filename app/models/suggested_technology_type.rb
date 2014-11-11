class SuggestedTechnologyType < ActiveRecord::Base
  include Seek::Ontologies::SuggestedType

  def ontology_readers
    [Seek::Ontologies::TechnologyTypeReader.instance]
  end

  def base_ontology_reader
    ontology_readers[0]
  end

  def self.all_term_types
    new.all_term_types
  end

  def term_type
    @term_type ||= base_ontology_reader.ontology_term_type
  end
end
