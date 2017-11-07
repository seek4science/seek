require 'test_helper'

class OntologyClassTest < ActiveSupport::TestCase
  test 'initialization' do
    o = Seek::Ontologies::OntologyClass.new RDF::URI.new('http://fish#bob')
    assert o.uri.is_a?(RDF::URI)
    assert_equal 'http://fish#bob', o.uri.to_s
    assert_nil o.description
    assert_empty o.subclasses

    o = Seek::Ontologies::OntologyClass.new RDF::URI.new('http://fish#bob'), 'fred'
    assert_equal 'http://fish#bob', o.uri.to_s
    assert_nil o.description
    assert_equal 'fred', o.label
    assert_empty o.subclasses

    o = Seek::Ontologies::OntologyClass.new RDF::URI.new('http://fish#bob'), 'fred', 'the fred'
    assert_equal 'http://fish#bob', o.uri.to_s
    assert_equal 'fred', o.label
    assert_equal 'the fred', o.description
    assert_empty o.subclasses

    o = Seek::Ontologies::OntologyClass.new RDF::URI.new('http://fish#bob'), 'fred', 'the fred', [RDF::URI.new('http://fish#baby_bob')]
    assert_equal 'http://fish#bob', o.uri.to_s
    assert_equal 'fred', o.label
    assert_equal 'the fred', o.description
    assert_equal 1, o.subclasses.count
    assert_equal 'http://fish#baby_bob', o.subclasses.first.to_s

    o = Seek::Ontologies::OntologyClass.new RDF::URI.new('http://fish#bob'), 'fred', 'the fred', [RDF::URI.new('http://fish#baby_bob')], [], 'assay'
    assert_equal 'http://fish#bob', o.uri.to_s
    assert_equal 'fred', o.label
    assert_equal 'the fred', o.description
    assert_equal 1, o.subclasses.count
    assert_equal 'http://fish#baby_bob', o.subclasses.first.to_s
    assert_equal 'assay', o.term_type
  end

  test 'flattened' do
    o1 = Seek::Ontologies::OntologyClass.new RDF::URI.new('http://o1')
    o2 = Seek::Ontologies::OntologyClass.new RDF::URI.new('http://o2')
    o3 = Seek::Ontologies::OntologyClass.new(RDF::URI.new('http://o3'), nil, nil, [o1, o2])
    o4 = Seek::Ontologies::OntologyClass.new(RDF::URI.new('http://o4'), nil, nil, [o3])

    list = o4.flatten_hierarchy
    assert_equal 4, list.count
    assert_includes list, o1
    assert_includes list, o2
    assert_includes list, o3
    assert_includes list, o4
  end

  test 'hash_by_uri' do
    o1 = Seek::Ontologies::OntologyClass.new RDF::URI.new('http://o1')
    o2 = Seek::Ontologies::OntologyClass.new RDF::URI.new('http://o2')
    o3 = Seek::Ontologies::OntologyClass.new(RDF::URI.new('http://o3'), nil, nil, [o1, o2])
    o4 = Seek::Ontologies::OntologyClass.new(RDF::URI.new('http://o4'), nil, nil, [o3])
    hash = o4.hash_by_uri

    assert_equal 4, hash.keys.count
    assert_equal o2, hash[o2.uri.to_s]
    assert_equal o4, hash[o4.uri.to_s]
  end

  test 'hash by label' do
    o1 = Seek::Ontologies::OntologyClass.new RDF::URI.new('http://o1'), 'o1'
    o2 = Seek::Ontologies::OntologyClass.new RDF::URI.new('http://o2')
    o3 = Seek::Ontologies::OntologyClass.new(RDF::URI.new('http://o3'), 'O3', nil, [o1, o2])
    o4 = Seek::Ontologies::OntologyClass.new(RDF::URI.new('http://o4'), 'o4', nil, [o3])

    hash = o4.hash_by_label

    assert_equal 4, hash.keys.count
    assert_equal o1, hash['o1']

    # key should be downcased
    assert_equal o3, hash['o3']
    assert_nil hash['O3']
  end

  test 'uri as string' do
    o = Seek::Ontologies::OntologyClass.new 'http://fish#bob'
    assert o.uri.is_a?(RDF::URI)
  end

  test 'must have uri' do
    assert_raises(Exception) do
      Seek::Ontologies::OntologyClass.new(nil, 'fred')
    end
  end

  test 'label if missing' do
    o = Seek::Ontologies::OntologyClass.new RDF::URI.new('http://fish#bob_monkhouse')
    assert_equal 'Bob monkhouse', o.label
  end
end
