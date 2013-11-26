require 'test_helper'


class OntologyClassTest < ActiveSupport::TestCase


  test "initialization" do

    o = Seek::Ontologies::OntologyClass.new RDF::URI.new("http://fish#bob")
    assert o.uri.kind_of?(RDF::URI)
    assert_equal "http://fish#bob",o.uri.to_s
    assert_nil o.description
    assert_empty o.subclasses

    o = Seek::Ontologies::OntologyClass.new RDF::URI.new("http://fish#bob"),"fred"
    assert_equal "http://fish#bob",o.uri.to_s
    assert_nil o.description
    assert_equal "fred",o.label
    assert_empty o.subclasses

    o = Seek::Ontologies::OntologyClass.new RDF::URI.new("http://fish#bob"),"fred","the fred"
    assert_equal "http://fish#bob",o.uri.to_s
    assert_equal "fred",o.label
    assert_equal "the fred",o.description
    assert_empty o.subclasses

    o = Seek::Ontologies::OntologyClass.new RDF::URI.new("http://fish#bob"),"fred","the fred",[RDF::URI.new("http://fish#baby_bob")]
    assert_equal "http://fish#bob",o.uri.to_s
    assert_equal "fred",o.label
    assert_equal "the fred",o.description
    assert_equal 1, o.subclasses.count
    assert_equal "http://fish#baby_bob",o.subclasses.first.to_s

  end

  test "uri as string" do
    o = Seek::Ontologies::OntologyClass.new "http://fish#bob"
    assert o.uri.kind_of?(RDF::URI)
  end

  test "must have uri" do
    assert_raises(Exception) do
      Seek::Ontologies::OntologyClass.new(nil,"fred")
    end
  end

  test "label if missing" do
    o = Seek::Ontologies::OntologyClass.new RDF::URI.new("http://fish#bob_monkhouse")
    assert_equal "bob monkhouse",o.label
  end

end