require 'test_helper'

class AssayAssetTest < ActiveSupport::TestCase
  def setup
    User.current_user = FactoryBot.create :user
  end

  def teardown
    User.current_user = nil
  end

  test 'links to latest version' do
    sop = FactoryBot.create :sop, contributor: User.current_user.person
    sop.save_as_new_version
    assay = FactoryBot.create :assay, contributor: User.current_user.person

    version_number = sop.version

    aa = AssayAsset.new
    aa.asset = sop
    aa.assay = assay

    aa.save!
    aa.reload

    sop.save_as_new_version

    assert_not_equal sop.version, aa.version
    assert_equal version_number, aa.version
    assert_equal assay, aa.assay
    assert_equal sop, aa.asset
  end

  test 'direction' do
    person = FactoryBot.create(:person)

    assert_equal 1, AssayAsset::Direction::INCOMING
    assert_equal 2, AssayAsset::Direction::OUTGOING
    assert_equal 0, AssayAsset::Direction::NODIRECTION

    User.with_current_user(person.user) do
      a = AssayAsset.new
      a.assay = FactoryBot.create(:assay, contributor:person)
      a.asset = FactoryBot.create(:sop, contributor:person)
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


  end

  test 'sample as asset' do
    person = FactoryBot.create(:person)

    User.with_current_user(person.user) do
      sample = FactoryBot.create(:sample, contributor:person)
      assay = FactoryBot.create(:assay, contributor:person)
      a = AssayAsset.new asset: sample, assay: assay, direction: AssayAsset::Direction::OUTGOING
      assert a.valid?
      a.save!
      a.reload
      assert_equal sample, a.asset
      assert_equal assay, a.assay
    end

  end

  test 'validate with model requires modelling assay' do
    person = FactoryBot.create(:person)
    User.with_current_user(person.user) do
      asset = FactoryBot.create(:model, contributor:person)
      assay1 = FactoryBot.create(:modelling_assay, contributor:person)
      assay2 = FactoryBot.create(:experimental_assay, contributor:person)

      assert assay1.can_edit?
      assert assay2.can_edit?

      assert assay1.is_modelling?
      refute assay2.is_modelling?

      a = AssayAsset.new asset: asset, assay: assay1
      assert a.valid?

      a = AssayAsset.new asset: asset, assay: assay2
      refute a.valid?
    end
  end

  test 'validate with data file requires any assay' do
    person = FactoryBot.create(:person)
    User.with_current_user(person.user) do
      asset = FactoryBot.create(:data_file, contributor:person)
      assay1 = FactoryBot.create(:modelling_assay, contributor:person)
      assay2 = FactoryBot.create(:experimental_assay, contributor:person)

      assert assay1.can_edit?
      assert assay2.can_edit?

      assert assay1.is_modelling?
      refute assay2.is_modelling?

      a = AssayAsset.new asset: asset, assay: assay1
      assert a.valid?

      a = AssayAsset.new asset: asset, assay: assay2
      assert a.valid?
    end
  end
end
