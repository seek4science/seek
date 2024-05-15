require 'test_helper'

class ObservationUnitTest < ActiveSupport::TestCase

  test 'max factory' do
    obs_unit = FactoryBot.create(:max_observation_unit)
    refute_nil obs_unit.created_at
    refute_nil obs_unit.updated_at
    refute_empty obs_unit.projects
    refute_empty obs_unit.creators
    refute_nil obs_unit.other_creators
    refute_nil obs_unit.extended_metadata
    refute_nil obs_unit.extended_metadata.extended_metadata_type
    refute_nil obs_unit.study
    refute_empty obs_unit.study.observation_units
    refute_empty obs_unit.samples
    refute_empty obs_unit.data_files
  end


  test 'to rdf' do
    obs_unit = FactoryBot.create(:max_observation_unit)
    assert obs_unit.rdf_supported?
    rdf = obs_unit.to_rdf
    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count > 1
      assert_equal RDF::URI.new("http://localhost:3000/observation_units/#{obs_unit.id}"), reader.statements.first.subject
      type = reader.statements.detect{|s| s.predicate == RDF.type}
      assert_equal RDF::URI('http://purl.org/ppeo/PPEO.owl#observation_unit'), type.object
    end
  end


end