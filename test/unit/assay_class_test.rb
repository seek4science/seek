require 'test_helper'

class AssayClassTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  fixtures :assay_classes
  test 'for_type' do
    assert_equal 'EXP', AssayClass.experimental.key
    assert_equal 'MODEL', AssayClass.modelling.key
  end

  test 'is_modelling?' do
    assert AssayClass.modelling.is_modelling?
    refute AssayClass.experimental.is_modelling?
  end
end
