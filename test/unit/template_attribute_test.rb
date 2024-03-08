require 'test_helper'

class TemplateAttributeTest < ActiveSupport::TestCase

  test 'allow isa tag change' do
    # When template doesn't have child templates => editable
    # When template has child templates => disabled
    string_type = FactoryBot.create(:string_sample_attribute_type)

    parent_attribute = FactoryBot.create(:template_attribute,
                                         sample_attribute_type: string_type)
    child_attribute = FactoryBot.create(:template_attribute,
                                        parent_attribute: parent_attribute,
                                        sample_attribute_type: string_type)
    parentless_attribute = FactoryBot.create(:template_attribute, sample_attribute_type: string_type)
    assert parentless_attribute.allow_isa_tag_change?
    refute child_attribute.allow_isa_tag_change?
  end
end
