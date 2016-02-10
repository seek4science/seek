require 'test_helper'

class SampleTypeTest < ActiveSupport::TestCase

  test "validation" do
    sample_type = Factory :sample_type,:title=>"fish"
    assert sample_type.valid?
    sample_type.title=nil
    refute sample_type.valid?
    sample_type.title=""
    refute sample_type.valid?
  end

  test "test uuid generated" do
    sample_type = SampleType.new :title=>"fish"
    assert_nil sample_type.attributes["uuid"]
    sample_type.save
    assert_not_nil sample_type.attributes["uuid"]
  end

  test "samples" do
    sample_type = Factory :sample_type
    assert_empty sample_type.samples
    sample1 = Factory :sample, :sample_type=>sample_type
    sample2 = Factory :sample, :sample_type=>sample_type

    sample_type.reload
    assert_equal [sample1,sample2].sort,sample_type.samples.sort
  end

  test "sample_attribute initialize" do
    attribute = SampleType::SampleAttribute.new name:"fish",type:Integer
    assert_equal "fish",attribute.name
    assert_equal Integer, attribute.type.type
    refute attribute.required?

    attribute = SampleType::SampleAttribute.new name:"fish",type:Integer,required:true
    assert_equal "fish",attribute.name
    assert_equal Integer, attribute.type.type
    assert attribute.required?
  end

  test "sample attribute valid?" do
    attribute = SampleType::SampleAttribute.new name:"fish",type:Integer
    assert attribute.valid?
    attribute = SampleType::SampleAttribute.new name:"fish"
    refute attribute.valid?
    attribute = SampleType::SampleAttribute.new type:Integer
    refute attribute.valid?
    attribute = SampleType::SampleAttribute.new
    refute attribute.valid?
    attribute = SampleType::SampleAttribute.new name:"fish",type:"monkey"
    refute attribute.valid?
    attribute = SampleType::SampleAttribute.new name:"fish",type:Integer,required:"string"
    refute attribute.valid?
    attribute = SampleType::SampleAttribute.new name:1,type:Integer
    refute attribute.valid?
    attribute = SampleType::SampleAttribute.new name:"fish",type:1
    refute attribute.valid?
    attribute = SampleType::SampleAttribute.new name:"fish",type:Integer,regexp:"fish"
    refute attribute.valid?
  end

  test "sample attribute validate value" do
    attribute = SampleType::SampleAttribute.new name:"fish",type:"int"
    assert attribute.validate_value?(1)

    #this is obviously currently wrong and will be updated in a future iteration
    assert attribute.validate_value?("frog")

    assert attribute.validate_value?(nil)
    assert attribute.validate_value?('')

    attribute = SampleType::SampleAttribute.new name:"fish",type:"int",required:true

    refute attribute.validate_value?(nil)
    refute attribute.validate_value?('')
  end
  #
  test "sample attribute to json" do
    attribute = SampleType::SampleAttribute.new name:"fish",type:String, regexp:/yyy/,required:true
    json = attribute.to_json
    assert_equal %!{"name":"fish","type":{"type":"String","regexp":"/yyy/"},"required":true}!,json
  end

  test "sample attribute type valid?" do
    type = SampleType::SampleAttributeType.new(Integer)
    assert type.valid?
    assert_equal /.*/,type.regexp

    type = SampleType::SampleAttributeType.new(ActionPack)
    refute type.valid?

    type = SampleType::SampleAttributeType.new(Integer,"fish")
    refute type.valid?
  end

  test "sample attribute type validation" do
    type = SampleType::SampleAttributeType.new(Integer)
    assert type.validate_value?(1)
    refute type.validate_value?("fish")
    refute type.validate_value?(nil)

    type = SampleType::SampleAttributeType.new(String,/xxx/)
    assert type.validate_value?("xxx")
    refute type.validate_value?("fish")
    refute type.validate_value?(nil)
  end

  test "sample attribute type to json" do
    type = SampleType::SampleAttributeType.new(String,/xxx/)
    assert_equal %!{"type":"String","regexp":"/xxx/"}!,type.to_json
  end
end
