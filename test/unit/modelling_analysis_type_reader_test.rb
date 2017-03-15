require 'test_helper'

class ModellingAnalysisTypeReaderTest < ActiveSupport::TestCase
  test 'initialise' do
    reader = Seek::Ontologies::ModellingAnalysisTypeReader.instance
    refute_nil reader
    refute_nil reader.ontology
    assert reader.ontology.count > 500, 'should be over 500 statements'
  end

  test 'class hierarchy' do
    reader = Seek::Ontologies::ModellingAnalysisTypeReader.instance
    hierarchy = reader.class_hierarchy

    refute_nil hierarchy
    assert hierarchy.is_a?(Seek::Ontologies::OntologyClass)
    assert_equal 'http://www.mygrid.org.uk/ontology/JERMOntology#Model_analysis_type', hierarchy.uri.to_s

    hierarchy = hierarchy.subclasses

    refute_empty hierarchy
    signal = hierarchy.select { |t| t.uri.fragment == 'Signal_transduction' }
    assert_equal 1, signal.count
    assert_empty signal.first.subclasses
  end
end
