require 'test_helper'
class TemplateAttributeTest < ActiveSupport::TestCase

  test 'allow isa tag change' do
    # When template doesn't have child templates => editable
    # When template has child templates => disabled
    parent_attribute = FactoryBot.create(:template_attribute)
    child_attribute = FactoryBot.create(:template_attribute, parent_attribute: parent_attribute)
    parentless_attribute = FactoryBot.create(:template_attribute)
    assert parentless_attribute.allow_isa_tag_change?
    refute child_attribute.allow_isa_tag_change?
  end
end
