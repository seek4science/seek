require 'test_helper'

class SampleTypesHelperTest < ActionView::TestCase

  test 'attribute type link should indicate if free text is allowed' do

    st = FactoryBot.create(:simple_sample_type)
    allowed_attr = FactoryBot.create(:apples_controlled_vocab_attribute, sample_type: st, allow_cv_free_text: true)
    not_allowed_attr = FactoryBot.create(:apples_controlled_vocab_attribute, sample_type: st, allow_cv_free_text: false)

    assert_match /#{I18n.t('samples.allow_free_text_label_hint')}/, attribute_type_link(allowed_attr)
    refute_match /#{I18n.t('samples.allow_free_text_label_hint')}/, attribute_type_link(not_allowed_attr)

    # also for list
    allowed_attr = FactoryBot.create(:apples_list_controlled_vocab_attribute, sample_type: st, allow_cv_free_text: true)
    not_allowed_attr = FactoryBot.create(:apples_list_controlled_vocab_attribute, sample_type: st, allow_cv_free_text: false)

    assert_match /#{I18n.t('samples.allow_free_text_label_hint')}/, attribute_type_link(allowed_attr)
    refute_match /#{I18n.t('samples.allow_free_text_label_hint')}/, attribute_type_link(not_allowed_attr)

  end

end
