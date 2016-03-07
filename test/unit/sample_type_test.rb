require 'test_helper'

class SampleTypeTest < ActiveSupport::TestCase

  test "validation" do
    sample_type = SampleType.new :title=>"fish"
    refute sample_type.valid?
    sample_type.sample_attributes << Factory(:simple_string_sample_attribute, is_title:true, :sample_type => sample_type)

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
    sample_type = Factory(:simple_sample_type)
    assert_empty sample_type.samples
    sample1 = Factory :sample, :sample_type=>sample_type
    sample2 = Factory :sample, :sample_type=>sample_type

    sample_type.reload
    assert_equal [sample1,sample2].sort,sample_type.samples.sort
  end

  test "associate sample attribute default order" do
    sample_type = SampleType.new title:'sample type'
    attribute1 = Factory(:simple_string_sample_attribute, is_title:true, :sample_type => sample_type)
    attribute2 = Factory(:simple_string_sample_attribute, :sample_type => sample_type)
    sample_type.sample_attributes << attribute1
    sample_type.sample_attributes << attribute2
    sample_type.save!

    sample_type.reload

    assert_equal [attribute1, attribute2],sample_type.sample_attributes
  end

  test "associate sample attribute specify order" do
    sample_type = SampleType.new title:'sample type'
    attribute3 = Factory(:simple_string_sample_attribute, :pos => 3, :sample_type => sample_type)
    attribute2 = Factory(:simple_string_sample_attribute, :pos => 2, :sample_type => sample_type)
    attribute1 = Factory(:simple_string_sample_attribute, :pos => 1, is_title:true, :sample_type => sample_type)
    sample_type.sample_attributes << attribute3
    sample_type.sample_attributes << attribute2
    sample_type.sample_attributes << attribute1
    sample_type.save!

    sample_type.reload

    assert_equal [attribute1, attribute2, attribute3],sample_type.sample_attributes
  end

  #thorough tests of a fairly complex factory, as it will be used in a lot of other tests
  test 'patient sample type factory test' do
    name_type = Factory(:full_name_sample_attribute_type)
    assert name_type.validate_value?("George Bush")
    refute name_type.validate_value?("george bush")
    refute name_type.validate_value?("GEorge Bush")
    refute name_type.validate_value?("George BUsh")
    refute name_type.validate_value?("G(eorge Bush")
    refute name_type.validate_value?("George B2ush")
    refute name_type.validate_value?("George")

    age_type = Factory(:age_sample_attribute_type)
    assert age_type.validate_value?(22)
    assert age_type.validate_value?('97')
    refute age_type.validate_value?(-6)
    refute age_type.validate_value?("six")

    weight_type = Factory(:weight_sample_attribute_type)
    assert weight_type.validate_value?(22.223)
    assert weight_type.validate_value?('97.332')
    refute weight_type.validate_value?('97.332.44')
    refute weight_type.validate_value?(-6)
    refute weight_type.validate_value?(-6.4)
    refute weight_type.validate_value?('-6.4')
    refute weight_type.validate_value?("six")

    post_code = Factory(:postcode_sample_attribute_type)
    assert post_code.validate_value?("M13 9PL")
    assert post_code.validate_value?("M12 7PL")
    refute post_code.validate_value?("12 PL")
    refute post_code.validate_value?("m12 7pl")
    refute post_code.validate_value?("bob")

    type = Factory(:patient_sample_type)
    assert_equal "Patient data",type.title
    assert_equal ["full name","age","weight","address","postcode"],type.sample_attributes.collect(&:title)
    assert_equal [true,true,false,false,false],type.sample_attributes.collect(&:required)
  end

  test "validate value" do
    type = Factory(:patient_sample_type)
    assert type.validate_value?("full name","Fred Bloggs")
    refute type.validate_value?("full name","Fred 22")
    assert type.validate_value?("age",99)
    refute type.validate_value?("age","fish")
    assert_raise SampleType::UnknownAttributeException do
      type.validate_value?("monkey",2)
    end
  end

  test "must have one title attribute" do
    type = SampleType.new title:"No title"
    type.sample_attributes << Factory(:sample_attribute,:title=>"full name",:sample_attribute_type=>Factory(:full_name_sample_attribute_type),:required=>true,:is_title=>false, :sample_type => type)

    refute type.valid?
    type.sample_attributes << Factory(:sample_attribute,:title=>"full name title",:sample_attribute_type=>Factory(:full_name_sample_attribute_type),:required=>true,:is_title=>true, :sample_type => type)
    assert type.valid?

    type.save!

    type.sample_attributes << Factory(:sample_attribute,:title=>"2nd full name title",:sample_attribute_type=>Factory(:full_name_sample_attribute_type),:required=>true,:is_title=>true, :sample_type => type)
    refute type.valid?
  end


end
