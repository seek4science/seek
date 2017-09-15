require 'test_helper'

class DataFilesHelperTest < ActionView::TestCase
  test 'split_into_two_handles_empty' do
    arg = nil
    expected = [{}, {}]

    res = split_into_two(arg)
    assert_equal expected, res

    arg = {}

    res = split_into_two(arg)
    assert_equal expected, res
  end

  test 'split_into_two_handles_one' do
    arg = { lab: 'max'}
    expected = [{ lab: 'max'}, {}]

    res = split_into_two(arg)
    assert_equal expected, res

  end

  test 'split_into_two_handles_odd' do
    arg = { lab: 'max', opo: 'cos', zed: 'bla'}
    expected = [{ lab: 'max', opo: 'cos'}, { zed: 'bla'}]

    res = split_into_two(arg)
    assert_equal expected, res
  end

  test 'split_into_two_handles_even' do
    arg = { lab: 'max', opo: 'cos', red: 'blue', zed: 'bla'}
    expected = [{ lab: 'max', opo: 'cos'}, { red: 'blue', zed: 'bla'}]

    res = split_into_two(arg)
    assert_equal expected, res
  end

end
