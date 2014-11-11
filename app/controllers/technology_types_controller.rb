class TechnologyTypesController < ApplicationController

  include Seek::Ontologies::Controller::TypeHandler

  private

  def ontology_readers
    [Seek::Ontologies::TechnologyTypeReader.instance]
  end

end