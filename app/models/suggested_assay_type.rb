
class SuggestedAssayType < ActiveRecord::Base
  include Seek::Ontologies::SuggestedType

  def ontology_readers
    [Seek::Ontologies::ModellingAnalysisTypeReader.instance, Seek::Ontologies::AssayTypeReader.instance]
  end

  def base_ontology_reader
    if @term_type == Seek::Ontologies::ModellingAnalysisTypeReader.instance.ontology_term_type
      Seek::Ontologies::ModellingAnalysisTypeReader.instance
    elsif @term_type.nil? || @term_type == Seek::Ontologies::AssayTypeReader.instance.ontology_term_type
      Seek::Ontologies::AssayTypeReader.instance
    end
  end

  def self.all_term_types
    new.all_term_types
  end

  def term_type
    @term_type ||= ontology_parent.try(:term_type)
  end
end
