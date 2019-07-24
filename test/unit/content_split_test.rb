require 'test_helper'
class SplitTest < ActiveSupport::TestCase
  include Seek::ContentSplit
  test 'return instance of array' do
    assert_instance_of  Array, split_content('Hello world!')
  end
  test 'extract content' do
    assert_equal split_content('',10,5),[]
    assert_equal split_content('Hello world!',10,5),['Hello world!']
    assert_equal split_content('Hello world!',10,5),['Hello world!']
  end
  test 'raise error if overlap is greater then length' do
    assert_raises RuntimeError do
      split_content('Hello world!',2,2)
      split_content('Hello world!',2,3)
    end
  end
end
