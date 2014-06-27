require 'test_helper'

class ModelTest < ActiveSupport::TestCase
  test 'default size' do
    assert_equal '200x200', ModelImage::DEFAULT_SIZE
  end

  test 'large size' do
    assert_equal '1000x1000', ModelImage::LARGE_SIZE
  end
end
