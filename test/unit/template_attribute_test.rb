require 'test_helper'

class TemplateAttributeTest < ActiveSupport::TestCase

  def setup
    @string_type = FactoryBot.create(:string_sample_attribute_type)
    @registered_sample_multi_attribute_type = FactoryBot.create(:sample_multi_sample_attribute_type)
    @registered_sample_attribute_type = FactoryBot.create(:sample_sample_attribute_type)
  end

  test 'allow isa tag change' do
    # When template doesn't have child templates => editable
    # When template has child templates => disabled

    parent_attribute = FactoryBot.create(:template_attribute,
                                         sample_attribute_type: @string_type)
    child_attribute = FactoryBot.create(:template_attribute,
                                        parent_attribute: parent_attribute,
                                        sample_attribute_type: @string_type)
    parentless_attribute = FactoryBot.create(:template_attribute, sample_attribute_type: @string_type)
    assert parentless_attribute.allow_isa_tag_change?
    refute child_attribute.allow_isa_tag_change?
  end

  test 'is input attribute?' do
    # When isa tag is nil, title includes 'input' and sample attribute type is seek sample multi => true
    # Otherwise => false

    attribute = FactoryBot.create(:template_attribute,
                                  sample_attribute_type: @registered_sample_multi_attribute_type,
                                  title: 'Input attribute')
    assert attribute.input_attribute?
    attribute.isa_tag = FactoryBot.create(:source_characteristic_isa_tag)
    refute attribute.input_attribute?
  end
end
