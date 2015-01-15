require 'test_helper'

class AssaysHelperTest < ActionView::TestCase

  include AssaysHelper
  include AssetsHelper

  test "authorised_assays" do
    p1=Factory :person
    p2=Factory :person

    #2 assays of the same project, but different contributors
    a1 = Factory :assay,:contributor=>p1,:policy=>Factory(:downloadable_public_policy)
    a2 = Factory :assay,:study=>a1.study,:contributor=>p2,:policy=>Factory(:downloadable_public_policy)

    a3 = Factory :assay,:contributor=>p1,:policy=>Factory(:downloadable_public_policy)
    a4 = Factory :assay,:study=>a3.study,:contributor=>p2,:policy=>Factory(:downloadable_public_policy)

    assert_equal a1.projects,a2.projects
    assert_equal a3.projects,a4.projects
    refute_equal a1.projects,a3.projects

    User.with_current_user(p1.user) do
      assays = authorised_assays(nil,"download")
      assert_equal [a1,a2,a3,a4],assays

      assays = authorised_assays
      assert_equal [a1,a3],assays

      assays = authorised_assays(a1.projects,"download")
      assert_equal [a1,a2],assays

      assays = authorised_assays a1.projects,"edit"
      assert_equal [a1],assays
    end

  end

end