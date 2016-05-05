require 'test_helper'

class CVAttributeTypeHandlerTest  < ActiveSupport::TestCase

  test 'test value' do
    handler = Seek::Samples::AttributeTypeHandlers::CVAttributeTypeHandler.new
    vocab = Factory(:apples_sample_controlled_vocab)
    handler.test_value('Granny Smith',:controlled_vocab=>vocab)
    assert_raises(RuntimeError) do
      handler.test_value('Pear',:controlled_vocab=>vocab)
    end
  end

  test 'validate value' do
    handler = Seek::Samples::AttributeTypeHandlers::CVAttributeTypeHandler.new
    vocab = Factory(:apples_sample_controlled_vocab)
    assert handler.validate_value?('Granny Smith',:controlled_vocab=>vocab)
    refute handler.validate_value?('Pear',:controlled_vocab=>vocab)
  end

end