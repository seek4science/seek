require 'test_helper'

class ModelTypeTest < ActiveSupport::TestCase

  test 'validation' do
    existing = model_types(:ODE)
    m = ModelType.new(title: existing.title)

    assert !m.valid?
    m.title = ''
    assert !m.valid?
    m.title = 'zxzxclzxczxcczx'
    assert m.valid?
  end
end
