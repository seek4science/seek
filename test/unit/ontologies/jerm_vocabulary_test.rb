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
    assert_equal RDF::URI.new('http://jermontology.org/ontology/JERMOntology#Assay'), Seek::Rdf::JERMVocab.Assay
  end

  test 'for type' do
    assert_equal RDF::URI.new('http://jermontology.org/ontology/JERMOntology#Data'), Seek::Rdf::JERMVocab.for_type(Factory :data_file)
    assert_equal RDF::URI.new('http://jermontology.org/ontology/JERMOntology#Model'), Seek::Rdf::JERMVocab.for_type(Factory :model)
    assert_equal RDF::URI.new('http://jermontology.org/ontology/JERMOntology#SOP'), Seek::Rdf::JERMVocab.for_type(Factory :sop)
    assert_equal RDF::URI.new('http://jermontology.org/ontology/JERMOntology#Assay'), Seek::Rdf::JERMVocab.for_type(Factory :assay)
    assert_equal RDF::URI.new('http://jermontology.org/ontology/JERMOntology#organism'), Seek::Rdf::JERMVocab.for_type(Factory :organism)
    assert_nil Seek::Rdf::JERMVocab.for_type(Factory :presentation)
  end
end
