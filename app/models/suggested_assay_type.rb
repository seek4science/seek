
class SuggestedAssayType < ActiveRecord::Base
  include Seek::Ontologies::SuggestedType

  def ontology_readers
    [Seek::Ontologies::AssayTypeReader.instance,Seek::Ontologies::ModellingAnalysisTypeReader.instance]
  end

  def self.all_term_types
    new.all_term_types
  end

  def term_type
    @term_type ||= ontology_parent.try(:term_type)
  end
end
