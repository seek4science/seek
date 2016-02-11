require 'test_helper'

class SampleAttributeTypeTest < ActiveSupport::TestCase

  test "valid?" do
    type = SampleAttributeType.new(title: "x-type",base_type:"Integer")
    assert type.valid?
    assert_equal ".*",type.regexp

    type = SampleAttributeType.new(base_type:"Integer")
    refute type.valid?

    type = SampleAttributeType.new(title: "x-type",base_type:"ActionPack")
    refute type.valid?

    type = SampleAttributeType.new(title: "x-type",base_type:"Fish")
    refute type.valid?

    type = SampleAttributeType.new(title: "x-type",base_type:"Integer",regexp:"[")
    refute type.valid?

    type = SampleAttributeType.new(title: "x-type",base_type:"String",regexp:"xxx")
    assert type.valid?
  end

  test "validate_value" do
    type = SampleAttributeType.new(title: "x-type",base_type:"Integer")
    assert type.validate_value?(1)
    refute type.validate_value?("fish")
    refute type.validate_value?(nil)

    type = SampleAttributeType.new(title: "x-type",base_type:"String",regexp:"xxx")
    assert type.validate_value?("xxx")
    refute type.validate_value?("fish")
    refute type.validate_value?(nil)
  end

  test "to json" do
    type = SampleAttributeType.new(title: "x-type",base_type:"String",regexp:"xxx")
    assert_equal %!{"title":"x-type","base_type":"String","regexp":"xxx"}!,type.to_json
  end

end
