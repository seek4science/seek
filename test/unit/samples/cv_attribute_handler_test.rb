require 'test_helper'

class CvAttributeHandlerTest < ActiveSupport::TestCase

  test 'test value' do
    st = FactoryBot.create(:simple_sample_type)
    attr = FactoryBot.create(:apples_controlled_vocab_attribute, sample_type: st)
    handler = Seek::Samples::AttributeHandlers::CvAttributeHandler.new(attr)

    handler.test_value('Granny Smith')
    assert_raises(RuntimeError) do
      handler.test_value('Pear')
    end
  end

  test 'validate value' do
    st = FactoryBot.create(:simple_sample_type)
    attr = FactoryBot.create(:apples_controlled_vocab_attribute, allow_cv_free_text: false, sample_type: st)
    handler = Seek::Samples::AttributeHandlers::CvAttributeHandler.new(attr)
    assert handler.validate_value?('Granny Smith')
    refute handler.validate_value?('Pear')
  end

  test 'exception thrown for missing controlled vocab' do
    st = FactoryBot.create(:simple_sample_type)
    attr = FactoryBot.create(:simple_string_sample_attribute, sample_type: st)
    assert_nil attr.sample_controlled_vocab
    handler = Seek::Samples::AttributeHandlers::CvAttributeHandler.new(attr)
    assert_raises(Seek::Samples::AttributeHandlers::CvAttributeHandler::MissingControlledVocabularyException) do
      assert handler.validate_value?('Granny Smith')
    end
  end

  test 'bypass validation for controlled vocabs together with allow_cv_free_text' do
    st = FactoryBot.create(:simple_sample_type)
    attr = FactoryBot.create(:apples_controlled_vocab_attribute, allow_cv_free_text: true, sample_type: st)
    handler = Seek::Samples::AttributeHandlers::CvAttributeHandler.new(attr)
    assert handler.validate_value?('Granny Smith')
    assert handler.validate_value?('custom value')
  end

end
