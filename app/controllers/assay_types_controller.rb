class AssayTypesController < ApplicationController
  include Seek::Ontologies::Controller::TypeHandler

  private

  def ontology_readers
    [Seek::Ontologies::AssayTypeReader.instance,Seek::Ontologies::ModellingAnalysisTypeReader.instance]
  end

end
