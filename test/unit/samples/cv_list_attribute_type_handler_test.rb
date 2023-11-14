require 'test_helper'

class CVListAttributeTypeHandlerTest < ActiveSupport::TestCase
  test 'test value' do
    handler = Seek::Samples::AttributeTypeHandlers::CVListAttributeTypeHandler.new
    vocab = FactoryBot.create(:apples_sample_controlled_vocab)
    handler.send('additional_options=', controlled_vocab: vocab)
    assert handler.test_value(['Granny Smith'])
    assert handler.test_value(['Granny Smith','Bramley'])

  end

  test 'validate value' do
    vocab = FactoryBot.create(:apples_sample_controlled_vocab)
    handler = Seek::Samples::AttributeTypeHandlers::CVListAttributeTypeHandler.new(controlled_vocab: vocab)
    assert handler.validate_value?(['Granny Smith','Bramley'])
    refute handler.validate_value?(['Peter'])
    refute handler.validate_value?('Granny Smith')

  end

  test 'exception thrown for missing controlled vocab' do
    handler = Seek::Samples::AttributeTypeHandlers::CVListAttributeTypeHandler.new
    assert_raises(Seek::Samples::AttributeTypeHandlers::CVListAttributeTypeHandler::MissingControlledVocabularyException) do
      assert handler.validate_value?(['Granny Smith'])
    end
  end

end
