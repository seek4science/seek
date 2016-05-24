require 'test_helper'

class CVAttributeTypeHandlerTest  < ActiveSupport::TestCase

  test 'test value' do
    handler = Seek::Samples::AttributeTypeHandlers::CVAttributeTypeHandler.new
    vocab = Factory(:apples_sample_controlled_vocab)
    handler.send('additional_options=',controlled_vocab:vocab)
    handler.test_value('Granny Smith')
    assert_raises(RuntimeError) do
      handler.test_value('Pear')
    end
  end

  test 'validate value' do
    handler = Seek::Samples::AttributeTypeHandlers::CVAttributeTypeHandler.new
    vocab = Factory(:apples_sample_controlled_vocab)
    assert handler.validate_value?('Granny Smith',:controlled_vocab=>vocab)
    refute handler.validate_value?('Pear',:controlled_vocab=>vocab)
  end

  test 'exception thrown for missing controlled vocab' do
    handler = Seek::Samples::AttributeTypeHandlers::CVAttributeTypeHandler.new
    assert_raises(Seek::Samples::AttributeTypeHandlers::CVAttributeTypeHandler::MissingControlledVocabularyException) do
      assert handler.validate_value?('Granny Smith')
    end
  end

end