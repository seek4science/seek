require 'test_helper'

class CVAttributeTypeHandlerTest < ActiveSupport::TestCase
  test 'test value' do
    handler = Seek::Samples::AttributeTypeHandlers::CVAttributeTypeHandler.new
    vocab = FactoryBot.create(:apples_sample_controlled_vocab)
    handler.send('additional_options=', controlled_vocab: vocab)
    handler.test_value('Granny Smith')
    assert_raises(RuntimeError) do
      handler.test_value('Pear')
    end
  end

  test 'validate value' do
    vocab = FactoryBot.create(:apples_sample_controlled_vocab)
    handler = Seek::Samples::AttributeTypeHandlers::CVAttributeTypeHandler.new(controlled_vocab: vocab)
    assert handler.validate_value?('Granny Smith')
    refute handler.validate_value?('Pear')
  end

  test 'exception thrown for missing controlled vocab' do
    handler = Seek::Samples::AttributeTypeHandlers::CVAttributeTypeHandler.new
    assert_raises(Seek::Samples::AttributeTypeHandlers::CVAttributeTypeHandler::MissingControlledVocabularyException) do
      assert handler.validate_value?('Granny Smith')
    end
  end

  test 'bypass validation for controlled vocabs set as custom input' do
    ontology_vocab = FactoryBot.create(:ontology_sample_controlled_vocab, custom_input: true)
    handler = Seek::Samples::AttributeTypeHandlers::CVAttributeTypeHandler.new(controlled_vocab: ontology_vocab)
    assert handler.validate_value?('Parent')
    assert handler.validate_value?('custom value')
  end

end
