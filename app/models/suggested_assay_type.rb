
class SuggestedAssayType < ActiveRecord::Base
  include Seek::Ontologies::SuggestedType

  before_destroy :update_assay_uri

  def ontology_readers
    [Seek::Ontologies::AssayTypeReader.instance, Seek::Ontologies::ModellingAnalysisTypeReader.instance]
  end

  def self.all_term_types
    new.all_term_types
  end

  def term_type
    @term_type ||= ontology_parent.try(:term_type)
  end

  # makes sure the assay keeps the ontology uri after destruction
  def update_assay_uri
    assays.each do |assay|
      disable_authorization_checks do
        assay.update_attribute(:assay_type_uri, ontology_uri)
      end
    end
  end
end
