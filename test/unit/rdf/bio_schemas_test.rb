require 'test_helper'

class BioSchemaTest < ActiveSupport::TestCase
  test 'supported?' do
    p = Factory(:person)
    not_supported = unsupported_type

    assert Seek::Rdf::BioSchema.supported?(p)
    refute Seek::Rdf::BioSchema.supported?(not_supported)
  end

  test 'exception for unsupported type' do
    o = unsupported_type
    assert_raise Seek::Rdf::BioSchema::UnsupportedTypeException do
      Seek::Rdf::BioSchema.new(o).json_ld
    end
  end

  test 'person wrapper test' do
    p = Factory(:person, first_name: 'Bob', last_name: 'Monkhouse', description: 'I am a person', avatar:Factory(:avatar))
    refute_nil p.avatar
    wrapper = Seek::Rdf::BioSchemaResourceWrappers::Person.new(p)
    assert_equal p.id, wrapper.id
    assert_equal p.title, wrapper.title
    assert_equal p.first_name, wrapper.first_name
    assert_equal p.last_name, wrapper.last_name
    assert_equal p.description, wrapper.description
    assert_equal "http://localhost:3000/people/#{p.id}/avatars/#{p.avatar.id}&size=250",wrapper.image
  end

  test 'person json_ld' do
    p = Factory(:person, first_name: 'Bob', last_name: 'Monkhouse', description: 'I am a person', avatar:Factory(:avatar))
    refute_nil p.avatar
    json = Seek::Rdf::BioSchema.new(p).json_ld
    json = JSON.parse(json)
    pp json
    assert_equal "http://localhost:3000/people/#{p.id}", json['@id']
    assert_equal 'Bob Monkhouse', json['name']
    assert_equal 'Person', json['@type']
    assert_equal 'I am a person',json['description']
    assert_equal 'Bob',json['givenName']
    assert_equal 'Monkhouse',json['familyName']
    refute_nil json['image']
    refute_nil json['@context']
  end

  private

  # an instance of a model that doesn't support bioschema / schema
  def unsupported_type
    Factory(:investigation)
  end
end
