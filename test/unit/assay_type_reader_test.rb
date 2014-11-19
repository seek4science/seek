require 'test_helper'


class AssayTypeReaderTest < ActiveSupport::TestCase

  test "initialise" do
    reader = Seek::Ontologies::AssayTypeReader.instance
    refute_nil reader
    refute_nil reader.ontology
    assert reader.ontology.count>500, "should be over 500 statements"
  end

  test "class hierarchy" do
    reader = Seek::Ontologies::AssayTypeReader.instance
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

  test "label exists?" do
    reader = Seek::Ontologies::AssayTypeReader.instance
    assert reader.label_exists?("amplification")
    assert reader.label_exists?("AmplifiCation") #case insensitive
    refute reader.label_exists?("sdkfhsdfkhsdfhksdf")
    refute reader.label_exists?(nil)
  end

  test "all labels" do
    reader = Seek::Ontologies::AssayTypeReader.instance
    labels = reader.all_labels
    assert_equal 52,labels.size
    assert_include labels,"amplification"
  end

  test "class for uri" do
    reader = Seek::Ontologies::AssayTypeReader.instance
    c = reader.class_for_uri("http://www.mygrid.org.uk/ontology/JERMOntology#Amplification")
    refute_nil c
    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#Amplification",c.uri
    assert_nil reader.class_for_uri("http://www.mygrid.org.uk/ontology/JERMOntology#sdfskdfhsdf")
  end

  test "parents are set" do
    amp = Seek::Ontologies::AssayTypeReader.instance.class_hierarchy.hash_by_uri["http://www.mygrid.org.uk/ontology/JERMOntology#Amplification"]
    refute_nil amp
    assert_equal 1,amp.parents.count
    genomics = amp.parents.first
    assert_equal "Genomics",genomics.label
    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#Genomics",genomics.uri.to_s

    assert_equal 1,genomics.parents.count
    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#Experimental_assay_type",genomics.parents.first.uri.to_s


  end



end