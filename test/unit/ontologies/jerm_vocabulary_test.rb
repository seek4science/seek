require 'test_helper'

class JermVocabularyTest < ActiveSupport::TestCase
  test 'uri' do
    assert_equal RDF::URI.new('http://jermontology.org/ontology/JERMOntology#'), Seek::Rdf::JermVocab.to_uri
    assert_equal RDF::URI.new('http://jermontology.org/ontology/JERMOntology#'), Seek::Rdf::JermVocab
  end

  test 'properties' do
  end

  test 'classes' do
    assert_equal RDF::URI.new('http://jermontology.org/ontology/JERMOntology#Data'), Seek::Rdf::JermVocab.Data
    assert_equal RDF::URI.new('http://jermontology.org/ontology/JERMOntology#Model'), Seek::Rdf::JermVocab.Model
    assert_equal RDF::URI.new('http://jermontology.org/ontology/JERMOntology#SOP'), Seek::Rdf::JermVocab.SOP
    assert_equal RDF::URI.new('http://jermontology.org/ontology/JERMOntology#Experimental_assay'), Seek::Rdf::JermVocab.Experimental_assay
    assert_equal RDF::URI.new('http://jermontology.org/ontology/JERMOntology#Modelling_analysis'), Seek::Rdf::JermVocab.Modelling_analysis
    assert_equal RDF::URI.new('http://jermontology.org/ontology/JERMOntology#Simulation_data'), Seek::Rdf::JermVocab.Simulation_data
  end

end
