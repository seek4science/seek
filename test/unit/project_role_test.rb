require 'test_helper'

class ProjectRoleTest < ActiveSupport::TestCase
  fixtures :project_roles

  def test_pal_role
    role = ProjectRole.pal_role
    assert_equal project_roles(:pal),role
  end
end