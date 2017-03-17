require 'test_helper'

class JermVocabularyTest < ActiveSupport::TestCase
  test 'uri' do
    assert_equal RDF::URI.new('http://www.mygrid.org.uk/ontology/JERMOntology#'), Seek::Rdf::JERMVocab.to_uri
    assert_equal RDF::URI.new('http://www.mygrid.org.uk/ontology/JERMOntology#'), Seek::Rdf::JERMVocab
  end

  test 'properties' do
  end

  test 'classes' do
    assert_equal RDF::URI.new('http://www.mygrid.org.uk/ontology/JERMOntology#Data'), Seek::Rdf::JERMVocab.Data
    assert_equal RDF::URI.new('http://www.mygrid.org.uk/ontology/JERMOntology#Model'), Seek::Rdf::JERMVocab.Model
    assert_equal RDF::URI.new('http://www.mygrid.org.uk/ontology/JERMOntology#SOP'), Seek::Rdf::JERMVocab.SOP
    assert_equal RDF::URI.new('http://www.mygrid.org.uk/ontology/JERMOntology#Assay'), Seek::Rdf::JERMVocab.Assay
  end

  test 'for type' do
    assert_equal RDF::URI.new('http://www.mygrid.org.uk/ontology/JERMOntology#Data'), Seek::Rdf::JERMVocab.for_type(DataFile)
    assert_equal RDF::URI.new('http://www.mygrid.org.uk/ontology/JERMOntology#Data'), Seek::Rdf::JERMVocab.for_type(Factory :data_file)
    assert_equal RDF::URI.new('http://www.mygrid.org.uk/ontology/JERMOntology#Model'), Seek::Rdf::JERMVocab.for_type(Model)
    assert_equal RDF::URI.new('http://www.mygrid.org.uk/ontology/JERMOntology#SOP'), Seek::Rdf::JERMVocab.for_type(Sop)
    assert_equal RDF::URI.new('http://www.mygrid.org.uk/ontology/JERMOntology#Assay'), Seek::Rdf::JERMVocab.for_type(Assay)
    assert_nil Seek::Rdf::JERMVocab.for_type ActionView
  end
end
