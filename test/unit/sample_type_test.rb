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
    attribute = SampleType::SampleAttribute.new name:"fish",type:"int"
    assert_equal "fish",attribute.name
    assert_equal "int", attribute.type
    refute attribute.required?

    attribute = SampleType::SampleAttribute.new name:"fish",type:"int",required:true
    assert_equal "fish",attribute.name
    assert_equal "int", attribute.type
    assert attribute.required?
  end

  test "sample attribute valid?" do
    attribute = SampleType::SampleAttribute.new name:"fish",type:"int"
    assert attribute.valid?
    attribute = SampleType::SampleAttribute.new name:"fish"
    refute attribute.valid?
    attribute = SampleType::SampleAttribute.new type:"int"
    refute attribute.valid?
    attribute = SampleType::SampleAttribute.new
    refute attribute.valid?
    attribute = SampleType::SampleAttribute.new name:"fish",type:"monkey"
    refute attribute.valid?
    attribute = SampleType::SampleAttribute.new name:"fish",type:"int",required:"string"
    refute attribute.valid?
    attribute = SampleType::SampleAttribute.new name:1,type:"int"
    refute attribute.valid?
    attribute = SampleType::SampleAttribute.new name:"fish",type:1
    refute attribute.valid?
  end

  test "sample attribute allowed types" do
    assert_equal ["int","string","url"].sort,SampleType::SampleAttribute::ALLOWED_TYPES
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

  test "sample attribute to json" do
    attribute = SampleType::SampleAttribute.new name:"fish",type:"int",required:true
    json = attribute.to_json
    assert_equal %!{"name":"fish","type":"int","required":true}!,json
  end
end
