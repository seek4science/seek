require 'test_helper'

class RoleTest < ActiveSupport::TestCase
  fixtures :roles

  def test_pal_role
    role = Role.pal_role
    assert_equal roles(:pal),role
  end
end