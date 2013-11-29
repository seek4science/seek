require 'test_helper'


class AssayTypeReaderTest < ActiveSupport::TestCase

  test "initialise" do
    reader = Seek::Ontologies::AssayTypeReader.new
    refute_nil reader
    refute_nil reader.ontology
    assert reader.ontology.count>500, "should be over 500 statements"
  end

  test "class hierarchy" do
    reader = Seek::Ontologies::AssayTypeReader.new
    hierarchy = reader.class_hierarchy

    refute_nil hierarchy
    assert hierarchy.kind_of?(Seek::Ontologies::OntologyClass)
    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#Experimental_assay_type", hierarchy.uri.to_s

    hierarchy = hierarchy.subclasses

    refute_empty hierarchy
    genomics =  hierarchy.select{|t| t.uri.to_s == "http://www.mygrid.org.uk/ontology/JERMOntology#Genomics"}
    assert_equal 1,genomics.count
    refute_empty genomics.first.subclasses
    amp = genomics.first.subclasses.select{|t| t.uri.to_s == "http://www.mygrid.org.uk/ontology/JERMOntology#Amplification"}
    refute_empty amp
  end


end