require 'test_helper'

class StudiesHelperTest < ActionView::TestCase
  test 'show_batch_miappe_button' do
    refute show_batch_miappe_button?

    Factory(:simple_investigation_custom_metadata_type, title: 'MIAPPE metadata')
    refute show_batch_miappe_button?

    Factory(:study_custom_metadata_type_for_MIAPPE, title: 'Not MIAPPE')
    refute show_batch_miappe_button?

    Factory(:study_custom_metadata_type_for_MIAPPE, title: 'MIAPPE metadata')
    assert show_batch_miappe_button?
  end
end
