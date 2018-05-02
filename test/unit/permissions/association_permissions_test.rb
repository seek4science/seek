require 'test_helper'

# Test that check that models cannot be interlinked where the permissions shouldn't allow
#
# ... for example it shouldn't be possible to link an Assay to a Study if the Study isn't visible and in the same project
class AssociationPermissionsTest < ActiveSupport::TestCase

  def setup
    @person = Factory(:person)
    @user = @person.user
    @project = @person.projects.first

  end

  # study must be viewable and belong to the same project as the current user
  test 'assay linked to study' do
    User.with_current_user(@user) do
      assay = Factory(:assay,contributor:@person)
      good_study = Factory(:study, contributor:@person,investigation:Factory(:investigation,projects:[@project]))
      bad_study1 = Factory(:study, contributor: Factory(:person),investigation:Factory(:investigation,projects:[@project]))
      bad_study2 = Factory(:study, contributor: Factory(:person),policy:Factory(:public_policy))

      assert good_study.can_view?
      assert good_study.projects.include?(@project)

      refute bad_study1.can_view?
      assert bad_study1.projects.include?(@project)

      assert bad_study2.can_view?
      refute bad_study2.projects.include?(@project)

      assay.study = good_study

      assert assay.save

      assay.study = bad_study1
      refute assay.save

      assay.study = bad_study2
      refute assay.save

      # check it saves with the study already linked
      assay = Factory(:assay,study:bad_study1,contributor:@person)
      assay.title='fish'
      assert assay.save
    end
  end

  # investigation must be viewable and belong to the same project as the current user
  test 'study linked to investigation' do
    User.with_current_user(@user) do
      study = Factory(:study,contributor:@person)
      good_inv = Factory(:investigation, contributor:@person,projects:[@project])
      bad_inv1 = Factory(:investigation, contributor: Factory(:person),projects:[@project])
      bad_inv2 = Factory(:investigation, contributor: Factory(:person),policy:Factory(:public_policy))

      assert good_inv.can_view?
      assert good_inv.projects.include?(@project)

      refute bad_inv1.can_view?
      assert bad_inv1.projects.include?(@project)

      assert bad_inv2.can_view?
      refute bad_inv2.projects.include?(@project)

      study.investigation = good_inv

      assert study.save

      study.investigation = bad_inv1
      refute study.save

      study.investigation = bad_inv2
      refute study.save

      # check it saves with the study already linked
      study = Factory(:study,contributor:@person, investigation: bad_inv1)
      study.title='fish'
      assert study.save
    end
  end

  # assay must be editable
  test 'assets linked to assay' do
    User.with_current_user(@user) do

      [:data_file,:model,:sop, :sample, :document].each do |asset_type|
        good_assay = Factory(:assay,contributor:@person)
        bad_assay = Factory(:assay,policy:Factory(:publicly_viewable_policy))

        assert good_assay.can_edit?
        refute bad_assay.can_edit?
        assert bad_assay.can_view? #check is can actually be viewed

        asset = Factory(asset_type,contributor:@person)
        assert asset.can_edit?
        assert_empty asset.assays

        asset.assay_assets.build(assay:good_assay)
        assert asset.save
        asset.reload
        assert_equal [good_assay],asset.assays

        asset = Factory(asset_type,contributor:@person)
        assert asset.can_edit?
        assert_empty asset.assays

        asset.assay_assets.build(assay:bad_assay)
        refute asset.save
        asset.reload
        assert_empty asset.assays

        #check it only checks new links
        disable_authorization_checks do
          asset = Factory(asset_type,contributor:@person)
          asset.assay_assets.build(assay:bad_assay)
          assert asset.save
        end

        assert_equal [bad_assay],asset.assays
        asset.assay_assets.build(assay:good_assay)
        assert asset.save
        asset.reload
        assert_equal [good_assay, bad_assay].sort,asset.assays.sort
      end

    end
  end

end