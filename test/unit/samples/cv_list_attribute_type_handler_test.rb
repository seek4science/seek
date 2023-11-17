require 'test_helper'

class CVListAttributeTypeHandlerTest < ActiveSupport::TestCase

  test 'test value' do
    st = FactoryBot.create(:simple_sample_type)
    attr = FactoryBot.create(:apples_controlled_vocab_attribute, sample_type: st)
    handler = Seek::Samples::AttributeTypeHandlers::CVListAttributeTypeHandler.new(attr)
    assert handler.test_value(['Granny Smith'])
    assert handler.test_value(['Granny Smith','Bramley'])
  end

  test 'validate value' do
    st = FactoryBot.create(:simple_sample_type)
    attr = FactoryBot.create(:apples_controlled_vocab_attribute, sample_type: st)
    handler = Seek::Samples::AttributeTypeHandlers::CVListAttributeTypeHandler.new(attr)
    assert handler.validate_value?(['Granny Smith','Bramley'])
    refute handler.validate_value?(['Peter'])
    refute handler.validate_value?('Granny Smith')

  end

  test 'exception thrown for missing controlled vocab' do
    st = FactoryBot.create(:simple_sample_type)
    attr = FactoryBot.create(:simple_string_sample_attribute, sample_type: st)
    assert_nil attr.sample_controlled_vocab
    handler = Seek::Samples::AttributeTypeHandlers::CVListAttributeTypeHandler.new(attr)
    assert_raises(Seek::Samples::AttributeTypeHandlers::CVListAttributeTypeHandler::MissingControlledVocabularyException) do
      assert handler.validate_value?(['Granny Smith'])
    end
  end

end
