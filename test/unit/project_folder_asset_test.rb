require 'test_helper'

class ProjectFolderAssetTest < ActiveSupport::TestCase


  test "associations" do
    pf = Factory :project_folder
    sop = Factory :sop,:policy=>Factory(:public_policy),:projects=>[pf.project]
    pfa = ProjectFolderAsset.create :asset=>sop,:project_folder=>pf
    pfa.save!
    pfa.reload
    assert_equal sop,pfa.asset
    assert_equal pf,pfa.project_folder

    pf.reload
    assert_equal 1,pf.assets.count
    assert pf.assets.include?(sop)
    sop.reload
    assert_equal 1, sop.folders.count
    assert sop.folders.include?(pf)
  end

  test "dependents destroyed" do
    pf = Factory :project_folder
    sop = Factory :sop,:policy=>Factory(:public_policy),:projects=>[pf.project]
    pfa = ProjectFolderAsset.create :asset=>sop,:project_folder=>pf

    assert_difference("ProjectFolderAsset.count",-1) do
      sop.destroy
      assert_nil ProjectFolderAsset.find_by_id(pfa.id)
    end

    pf = Factory :project_folder
    sop = Factory :sop,:policy=>Factory(:public_policy),:projects=>[pf.project]
    pfa = ProjectFolderAsset.create :asset=>sop,:project_folder=>pf

    assert_difference("ProjectFolderAsset.count",-1) do
      pf.destroy
      assert_nil ProjectFolderAsset.find_by_id(pfa.id)
    end

  end


  test "validations" do
    pfa = ProjectFolderAsset.new
    pf = Factory :project_folder
    model = Factory :model,:policy=>Factory(:public_policy),:projects=>[pf.project]

    assert !pfa.valid?


    #must have asset and folder
    pfa.asset=model
    assert !pfa.valid?
    pfa.project_folder = pf
    assert pfa.valid?
    pfa.asset=nil
    assert !pfa.valid?

    #asset must belong in same project as folder
    pfa.asset=model
    assert pfa.valid?
    pfa.asset = Factory :model,:policy=>Factory(:public_policy),:projects=>[pf.project,Factory(:project)]
    assert pfa.valid?
    pfa.asset = Factory :model,:policy=>Factory(:public_policy),:projects=>[Factory(:project)]
    assert !pfa.valid?

    #final check for save
    pfa.asset=model
    assert pfa.save
  end
end
