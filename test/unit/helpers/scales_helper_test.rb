require 'test_helper'

class ScalesHelperTest < ActionView::TestCase
  test 'show scales?' do
    Scale.destroy_all
    assert !show_scales?
    Factory :scale
    assert show_scales?
  end
end
