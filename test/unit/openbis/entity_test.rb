require 'test_helper'
require 'openbis_test_helper'

class EntityTest < ActiveSupport::TestCase
  def setup
    mock_openbis_calls
    @openbis_endpoint = FactoryBot.create(:openbis_endpoint)
    @entity = Seek::Openbis::Entity.new(@openbis_endpoint)
  end

  test 'vet_properties removes XMLAnnotation and empty XMLComments' do
    hash = nil
    exp = {}
    assert_equal exp, @entity.vet_properties(hash)

    hash = {}
    assert_equal exp, @entity.vet_properties(hash)

    hash = { "XMLCOMMENTS": nil, "ANNOTATIONS_STATE": nil }
    assert_equal exp, @entity.vet_properties(hash)

    hash = { "XMLCOMMENTS": '?(undefined)', "ANNOTATIONS_STATE": '?(undefined)' }
    assert_equal exp, @entity.vet_properties(hash)

    hash = { "XMLCOMMENTS": 'shouldbexml', "ANNOTATIONS_STATE": '<root><p></p></root>' }
    assert_equal exp, @entity.vet_properties(hash)

    # non empty valid xml comment
    hash = { "XMLCOMMENTS": '<root><commentEntry date="1511277676686" person="seek">My first comment</commentEntry></root>' }
    assert_equal hash, @entity.vet_properties(hash)

    hash = { "GOAL": 'something', "XMLCOMMENTS": '?(undefined)', "ANNOTATIONS_STATE": '?(undefined)' }
    exp = { "GOAL": 'something' }
    assert_equal exp, @entity.vet_properties(hash)
  end
end
