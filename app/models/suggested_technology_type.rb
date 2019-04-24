class SuggestedTechnologyType < ApplicationRecord
  include Seek::Ontologies::SuggestedType

  before_destroy :update_assay_uri

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

  # makes sure the assay keeps the ontology uri after destruction
  def update_assay_uri
    assays.each do |assay|
      disable_authorization_checks do
        assay.update_attribute(:technology_type_uri, ontology_uri)
      end
    end
  end
end
