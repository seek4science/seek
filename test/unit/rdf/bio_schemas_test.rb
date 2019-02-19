require 'test_helper'

class BioSchemaTest < ActiveSupport::TestCase

  include Seek::Rdf

  test 'supported?' do
    p = Factory(:person)
    not_supported = unsupported_type

    assert Seek::Rdf::BioSchema.supported?(p)
    refute Seek::Rdf::BioSchema.supported?(not_supported)
  end

  test 'exception for unsupported type' do
    o = unsupported_type
    assert_raise Seek::Rdf::BioSchema::UnsupportedTypeException do
      BioSchema.new(o).json_ld
    end
  end

  private

  # an instance of a model that doesn't support bioschema / schema
  def unsupported_type
    Factory(:investigation)
  end

end