require 'test_helper'

class AssaysHelperTest < ActionView::TestCase
  include AssaysHelper
  include AssetsHelper

  test 'authorised_assays' do
    p1 = Factory :person
    p2 = Factory :person

    # 2 assays of the same project, but different contributors
    a1 = Factory :assay, contributor: p1, policy: Factory(:downloadable_public_policy)
    a2 = Factory :assay, study: a1.study, contributor: p2, policy: Factory(:downloadable_public_policy)

    a3 = Factory :assay, contributor: p1, policy: Factory(:downloadable_public_policy)
    a4 = Factory :assay, study: a3.study, contributor: p2, policy: Factory(:downloadable_public_policy)

    assert_equal a1.projects, a2.projects
    assert_equal a3.projects, a4.projects
    refute_equal a1.projects, a3.projects

    User.with_current_user(p1.user) do
      assays = authorised_assays(nil, 'download').sort_by(&:id)
      assert_equal [a1, a2, a3, a4], assays

      assays = authorised_assays.sort_by(&:id)
      assert_equal [a1, a3], assays

      assays = authorised_assays(a1.projects, 'download').sort_by(&:id)
      assert_equal [a1, a2], assays

      assays = authorised_assays(a1.projects, 'edit').sort_by(&:id)
      assert_equal [a1], assays
    end
  end

  test 'external_asset_details shows warnings on empty or unknown' do
    p1 = Factory :person
    a1 = Factory :assay, contributor: p1, policy: Factory(:downloadable_public_policy)

    res = external_asset_details(a1)
    assert_match /No external asset/, res

    a1.build_external_asset
    assert a1.external_asset

    res = external_asset_details(a1)
    assert_match /Unsupported external asset ExternalAsset/, res
  end

  test 'external_asset_details renders partial for openbis' do
    a1 = Assay.new # new so it the external wont be saved to file

    zample = Factory :openbis_zample

    external = OpenbisExternalAsset.build(zample)
    a1.external_asset = external

    res = external_asset_details(a1)
    assert_match /id="openbis-details"/, res
    assert_equal '20171002172111346-37', zample.perm_id
    assert_match /20171002172111346-37/, res

  end
end
