require 'test_helper'

class CustomMetadataTypeTest < ActiveSupport::TestCase

  test 'validation' do

    cmt = CustomMetadataType.new(title: 'test metadata', supported_type:'Investigation')
    refute cmt.valid?
    cmt.custom_metadata_attributes << Factory(:age_custom_metadata_attribute)
    assert cmt.valid?

    cmt.title=''
    refute cmt.valid?

    cmt.title='test'
    assert cmt.valid?

    cmt.supported_type=''
    refute cmt.valid?

    cmt.supported_type='Wibble'
    refute cmt.valid?

    cmt.supported_type='Seek::Docker'
    refute cmt.valid?

    cmt.supported_type='Study'
    assert cmt.valid?
  end

end