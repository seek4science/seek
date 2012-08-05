require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  
  def test_join_with_and
    
    assert_equal "a, b and c",join_with_and(["a","b","c"])
    assert_equal "a",join_with_and(["a"])
    assert_equal "a, b, c and d",join_with_and(["a","b","c","d"])
    assert_equal "a and b",join_with_and(["a","b"])
    assert_equal "a: b: c and d",join_with_and(["a","b","c","d"],": ")
  end

  test 'showing local time instead of GMT/UTC for date_as_string' do
    sop = Factory(:sop)
    created_at = sop.created_at

    assert created_at.utc?
    assert created_at.gmt?

    local_created_at = created_at.localtime
    assert !local_created_at.utc?
    assert !local_created_at.gmt?

    assert date_as_string(created_at, true).include?(local_created_at.strftime('%H:%M:%S'))
  end
end