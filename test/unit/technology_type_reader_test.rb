require 'test_helper'


class TechnologyTypeReaderTest < ActiveSupport::TestCase

  test "initialise" do
    reader = Seek::Ontologies::TechnologyTypeReader.instance
    refute_nil reader
    refute_nil reader.ontology
    assert reader.ontology.count>500, "should be over 500 statements"
  end

  test "class hierarchy" do
    reader = Seek::Ontologies::TechnologyTypeReader.instance
    hierarchy = reader.class_hierarchy

    refute_nil hierarchy
    assert hierarchy.kind_of?(Seek::Ontologies::OntologyClass)
    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#Technology_type", hierarchy.uri.to_s

    hierarchy = hierarchy.subclasses

    refute_empty hierarchy
    imaging =  hierarchy.select{|t| t.uri.fragment == "Imaging"}
    assert_equal 1,imaging.count
    refute_empty imaging.first.subclasses
    mic = imaging.first.subclasses.select{|t| t.uri.fragment == "Microscopy"}
    refute_empty mic
  end

  test "class for uri" do
    reader = Seek::Ontologies::TechnologyTypeReader.instance
    c = reader.class_for_uri("http://www.mygrid.org.uk/ontology/JERMOntology#Sequencing")
    refute_nil c
    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#Sequencing",c.uri
    assert_nil reader.class_for_uri("http://www.mygrid.org.uk/ontology/JERMOntology#sdfskdfhsdf")
  end

  test "label exists?" do
    reader = Seek::Ontologies::TechnologyTypeReader.instance
    assert reader.label_exists?("chip-seq")
    assert reader.label_exists?("Chip-Seq")
    refute reader.label_exists?("sdkfhsdfkhsdfhksdf")
    refute reader.label_exists?(nil)
  end

  test "all labels" do
    reader = Seek::Ontologies::TechnologyTypeReader.instance
    labels = reader.all_labels
    assert labels.size>50
    assert_include labels,"chip-seq"
  end


end