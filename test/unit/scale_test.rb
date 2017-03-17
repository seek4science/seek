require 'test_helper'
class ScaleTest < ActiveSupport::TestCase
  test 'title validation' do
    scale = Factory :scale, title: 'test'
    scale.title = ''
    assert !scale.valid?

    scale.reload
    new_scale = Factory.build :scale, title: 'test'
    assert !new_scale.save
  end

  test 'alias attributes name' do
    scale = Factory :scale
    scale.title = 'test'
    assert_equal 'test', scale.name
    scale.name = 'change'
    assert_equal 'change', scale.title
  end
end
