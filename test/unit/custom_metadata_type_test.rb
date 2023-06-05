require 'test_helper'

class CustomMetadataTypeTest < ActiveSupport::TestCase
  test 'validation' do
    cmt = CustomMetadataType.new(title: 'test metadata', supported_type: 'Investigation')
    refute cmt.valid?
    cmt.custom_metadata_attributes << FactoryBot.create(:age_custom_metadata_attribute)
    assert cmt.valid?

    cmt.title = ''
    refute cmt.valid?

    cmt.title = 'test'
    assert cmt.valid?

    cmt.supported_type = ''
    refute cmt.valid?

    cmt.supported_type = 'Wibble'
    refute cmt.valid?

    cmt.supported_type = 'Seek::Docker'
    refute cmt.valid?

    cmt.supported_type = 'Study'
    assert cmt.valid?
  end

  test 'validates attribute titles are unique' do
    cmt = CustomMetadataType.new(title: 'test unique attributes', supported_type: 'Investigation')
    cmt.custom_metadata_attributes << FactoryBot.create(:name_custom_metadata_attribute, title: 'name')
    assert cmt.valid?
    cmt.custom_metadata_attributes << FactoryBot.create(:name_custom_metadata_attribute, title: 'name2')
    assert cmt.valid?
    cmt.custom_metadata_attributes.last.title = 'name'
    refute cmt.valid?
    cmt.custom_metadata_attributes.last.title = 'name2'

    # check scope
    cmt2 = CustomMetadataType.new(title: 'test unique attributes', supported_type: 'Investigation')
    cmt2.custom_metadata_attributes << FactoryBot.create(:name_custom_metadata_attribute, title: 'name')
    assert cmt2.valid?
  end

  test 'attribute by title' do
    cmt = FactoryBot.create(:simple_investigation_custom_metadata_type)

    refute_nil (attr = cmt.attribute_by_title('name'))
    assert_equal 'name', attr.title

    assert_nil cmt.attribute_by_title('sdfkjsdhf')

    cmt = FactoryBot.create(:study_custom_metadata_type_with_spaces)

    refute_nil (attr = cmt.attribute_by_title('full name'))
    assert_equal 'full name', attr.title
  end
  
  test 'destroy' do
    cmt = FactoryBot.create(:simple_investigation_custom_metadata_type)
    attributes = cmt.custom_metadata_attributes
    assert_equal [], attributes.select(&:destroyed?)
    assert_equal 3, attributes.count
    assert_difference('CustomMetadataType.count',-1) do
      assert_difference('CustomMetadataAttribute.count',-3) do
        cmt.destroy
      end
    end
    assert cmt.destroyed?
    assert_equal attributes, attributes.select(&:destroyed?)
  end
end
