require 'test_helper'

class AssaysHelperTest < ActionView::TestCase
  include AssaysHelper
  include AssetsHelper

  test 'authorised_assays' do
    project = Factory(:project)
    other_project = Factory(:project)
    p1 = Factory :person, project: project
    p2 = Factory :person, project: project

    # 2 assays of the same project, but different contributors
    a1 = Factory :assay, contributor: p1, policy: Factory(:downloadable_public_policy)
    a2 = Factory :assay, study: a1.study, contributor: p2, policy: Factory(:downloadable_public_policy)

    assert_equal a1.projects, a2.projects

    User.with_current_user(p1.user) do
      assays = authorised_assays(nil, 'download').sort_by(&:id)
      assert_equal [a1, a2], assays

      # nothing matches the project
      assays = authorised_assays(other_project, 'download').sort_by(&:id)
      assert_empty assays

      assays = authorised_assays(a1.projects, 'edit').sort_by(&:id)
      assert_equal [a1], assays

      # edit is the default
      assays = authorised_assays.sort_by(&:id)
      assert_equal [a1], assays
    end
  end
end
