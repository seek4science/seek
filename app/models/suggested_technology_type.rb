class SuggestedTechnologyType < ActiveRecord::Base
  include Seek::Ontologies::SuggestedType

  def base_ontology_reader
      Seek::Ontologies::TechnologyTypeReader.instance
  end

  def self.base_ontology_hash_by_uri
     self.new.base_ontology_reader.class_hierarchy.hash_by_uri
  end

  def self.base_ontology_labels
    base_ontology_hash_by_label.keys
  end


  def term_type
      @term_type ||= base_ontology_reader.ontology_term_type
  end

  def self.all_term_types
    Array(self.new.base_ontology_reader.ontology_term_type)
  end


end
