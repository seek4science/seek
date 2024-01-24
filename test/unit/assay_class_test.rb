require 'test_helper'

class AssayClassTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  fixtures :assay_classes
  test 'for_type' do
    assert_equal 'EXP', AssayClass.for_type(Seek::ISA::AssayClass::EXP).key
    assert_equal 'MODEL', AssayClass.for_type(Seek::ISA::AssayClass::MODEL).key
  end

  test 'is_modelling?' do
    assert AssayClass.for_type(Seek::ISA::AssayClass::MODEL).is_modelling?
    refute AssayClass.for_type(Seek::ISA::AssayClass::EXP).is_modelling?
  end
end
