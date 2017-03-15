require 'test_helper'

class AssayAssetTest < ActiveSupport::TestCase
  def setup
    User.current_user = Factory :user
  end

  def teardown
    User.current_user = nil
  end

  test 'create explicit version' do
    sop = Factory :sop, contributor: User.current_user
    sop.save_as_new_version
    assay = Factory :assay, contributor: User.current_user.person

    version_number = sop.version

    a = AssayAsset.new
    a.asset = sop.latest_version
    a.assay = assay

    a.save!
    a.reload

    sop.save_as_new_version

    assert_not_equal(sop.latest_version, a.asset) # Check still linked to version made on create
    assert_equal(version_number, a.asset.version)
    assert_equal(sop.find_version(version_number), a.asset)

    assert_equal(assay, a.assay)
  end

  test 'direction' do
    assert_equal 1, AssayAsset::Direction::INCOMING
    assert_equal 2, AssayAsset::Direction::OUTGOING
    assert_equal 0, AssayAsset::Direction::NODIRECTION

    a = AssayAsset.new
    a.assay = Factory(:assay)
    a.asset = Factory(:sop).latest_version
    a.save!
    a.reload
    assert_equal 0, a.direction
    refute a.incoming_direction?
    refute a.outgoing_direction?

    a.direction = AssayAsset::Direction::INCOMING
    a.save!
    a.reload
    assert a.incoming_direction?
    refute a.outgoing_direction?

    a.direction = AssayAsset::Direction::OUTGOING
    a.save!
    a.reload
    refute a.incoming_direction?
    assert a.outgoing_direction?
  end

  test 'sample as asset' do
    sample = Factory(:sample)
    assay = Factory(:assay)
    a = AssayAsset.new asset: sample, assay: assay, direction: AssayAsset::Direction::OUTGOING
    assert a.valid?
    a.save!
    a.reload
    assert_equal sample, a.asset
    assert_equal assay, a.assay
  end
end
