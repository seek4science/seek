require 'test_helper'

class CVListAttributeTypeHandlerTest < ActiveSupport::TestCase
  test 'test value' do
    handler = Seek::Samples::AttributeTypeHandlers::CVListAttributeTypeHandler.new
    vocab = Factory(:apples_sample_controlled_vocab)
    handler.send('additional_options=', controlled_vocab: vocab)
    handler.test_value(['Granny Smith'])
    handler.test_value(['Granny Smith','Bramley'])
    assert_raises(Seek::Samples::AttributeTypeHandlers::CVListAttributeTypeHandler::NotArrayException) do
      handler.test_value('Granny Smith')
    end
    assert_raises(Seek::Samples::AttributeTypeHandlers::CVListAttributeTypeHandler::InvalidControlledVocabularyException) do
      handler.test_value(['Granny Smith','Peter'])
    end
  end

  test 'validate value' do
    vocab = Factory(:apples_sample_controlled_vocab)
    handler = Seek::Samples::AttributeTypeHandlers::CVListAttributeTypeHandler.new(controlled_vocab: vocab)
    assert handler.validate_value?(['Granny Smith','Bramley'])

    assert_raises(Seek::Samples::AttributeTypeHandlers::CVListAttributeTypeHandler::InvalidControlledVocabularyException) do
      assert handler.validate_value?(['Peter'])
    end
    assert_raises(Seek::Samples::AttributeTypeHandlers::CVListAttributeTypeHandler::NotArrayException) do
      assert handler.validate_value?('Granny Smith')
    end
  end

  test 'exception thrown for missing controlled vocab' do
    handler = Seek::Samples::AttributeTypeHandlers::CVListAttributeTypeHandler.new
    assert_raises(Seek::Samples::AttributeTypeHandlers::CVListAttributeTypeHandler::MissingControlledVocabularyException) do
      assert handler.validate_value?(['Granny Smith'])
    end
  end

end
