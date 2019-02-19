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

  test 'json_ld' do
    p = Factory(:person, first_name:'Bob',last_name: 'Monkhouse', description:'I am a person')
    json = Seek::Rdf::BioSchema.new(p).json_ld
    json = JSON.parse(json)
    pp json
    assert_equal "http://localhost:3000/people/#{p.id}",json['@id']
    assert_equal "Bob Monkhouse",json['name']
    assert_equal 'Person',json['@type']
    refute_nil json['@context']
  end

  private

  # an instance of a model that doesn't support bioschema / schema
  def unsupported_type
    Factory(:investigation)
  end

end