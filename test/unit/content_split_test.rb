require 'test_helper'
class SplitTest < ActiveSupport::TestCase
  include Seek::ContentSplit

  content = 'The final parameter set was selected based on the best overal metabolite concentration and ' +
            'flux prediction.'

  test 'return instance of array' do
    assert_instance_of  Array, split_content(content,10,5)
  end
  test 'extract content' do
    assert_equal split_content('',10,5),[]
    assert_equal split_content(content,10,5),
                 ['The final parameter set was selected based on the best',
                  'selected based on the best overal metabolite concentration and flux',
                  'overal metabolite concentration and flux prediction.']
  end
  test 'raise error if overlap is greater then length' do
    assert_raises RuntimeError do
      split_content(content,2,2)
      split_content(content,2,3)
    end
  end
end
