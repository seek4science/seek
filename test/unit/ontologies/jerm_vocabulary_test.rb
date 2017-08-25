require 'test_helper'

class JermVocabularyTest < ActiveSupport::TestCase
  test 'uri' do
    assert_equal RDF::URI.new('http://jermontology.org/ontology/JERMOntology#'), Seek::Rdf::JERMVocab.to_uri
    assert_equal RDF::URI.new('http://jermontology.org/ontology/JERMOntology#'), Seek::Rdf::JERMVocab
  end

  test 'properties' do
  end

  test 'classes' do
    assert_equal RDF::URI.new('http://jermontology.org/ontology/JERMOntology#Data'), Seek::Rdf::JERMVocab.Data
    assert_equal RDF::URI.new('http://jermontology.org/ontology/JERMOntology#Model'), Seek::Rdf::JERMVocab.Model
    assert_equal RDF::URI.new('http://jermontology.org/ontology/JERMOntology#SOP'), Seek::Rdf::JERMVocab.SOP
    assert_equal RDF::URI.new('http://jermontology.org/ontology/JERMOntology#experimental_assay'), Seek::Rdf::JERMVocab.experimental_assay
    assert_equal RDF::URI.new('http://jermontology.org/ontology/JERMOntology#modelling_analysis'), Seek::Rdf::JERMVocab.modelling_analysis
  end

end
