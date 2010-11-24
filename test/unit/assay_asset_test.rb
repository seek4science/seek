require 'test_helper'

class AssayAssetTest < ActiveSupport::TestCase
  fixtures :all

  test "create explicit version" do
    sop = sops(:my_first_sop)
    sop.save_as_new_version
    assay = assays(:metabolomics_assay)

    version_number = sop.version

    a = AssayAsset.new
    a.asset = sop.latest_version
    a.assay = assay

    a.save!
    a.reload

    sop.save_as_new_version

    assert_not_equal(sop.latest_version, a.asset) #Check still linked to version made on create    
    assert_equal(version_number,a.asset.version)
    assert_equal(sop.find_version(version_number), a.asset)
    
    assert_equal(assay, a.assay)
  end   
  
  test "versioned asset" do
    sop = sops(:my_first_sop)
    sop.save_as_new_version
    assay = assays(:metabolomics_assay)
    
    a = AssayAsset.new
    a.asset = sop.latest_version
    a.assay = assay
    a.version=1
    a.save!
        
    assert_equal 1,a.versioned_asset.version
    assert_equal sop.find_version(1),a.versioned_asset
    
    a = AssayAsset.new
    a.asset = sop.latest_version
    a.assay = assay    
    a.save!
    
    assert_equal sop.version,a.versioned_asset.version
    assert_equal sop.latest_version,a.versioned_asset    
  end
  
end
