require 'test_helper'

class AssayAssetTest < ActiveSupport::TestCase
  fixtures :all

  test "create explicit version" do
    sop=sops(:my_first_sop)
    sop.save_as_new_version
    assay=assays(:metabolomics_assay)

    a=AssayAsset.new
    a.asset=sop.asset
    a.assay=assay
    a.version=3

    a.save!

    assert_equal(sop.asset, a.asset)
    assert_equal(assay, a.assay)
    assert_equal(3,a.version)    
  end

  test "create implied version" do
    sop=sops(:my_first_sop)
    sop.save_as_new_version

    assert_equal(2,sop.version)
    assert_equal(2,sop.asset.resource.version)

    assay=assays(:metabolomics_assay)

    a=AssayAsset.new
    a.asset=sop.asset
    assert_equal(2,a.asset.resource.version)
    
    a.assay=assay

    a.save!

    assert_equal(sop.asset, a.asset)
    assert_equal(assay, a.assay)
    assert_equal(sop.version,a.version)
  end

  def test_versioned_resource
    sop=sops(:my_first_sop)
    sop.save_as_new_version #to make a version
    assay=assays(:metabolomics_assay)

    a=AssayAsset.new
    a.asset=sop.asset
    a.assay=assay
    a.version=2

    a.save!

    assert_equal(sop.asset, a.asset)
    assert_equal(assay, a.assay)
    assert_equal(sop.version,a.version)
    assert_equal(sop.find_version(2),a.versioned_resource)
  end

  def test_sops
    AssayAsset.sops
  end
  
end
