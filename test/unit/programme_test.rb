require 'test_helper'

class ProgrammeTest < ActiveSupport::TestCase

  test "uuid" do
    p = Programme.new :title=>"fish"
    assert_nil p.attributes["uuid"]
    p.save!
    refute_nil p.attributes["uuid"]
    uuid = p.uuid
    p.title="frog"
    p.save!
    assert_equal uuid,p.uuid
  end

  test "validation" do
    p = Programme.new
    refute p.valid?
    p.title="frog"
    assert p.valid?
  end

  test "factory" do
    p = Factory :programme
    refute_nil p.title
    refute_nil p.uuid
  end

end
