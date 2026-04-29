require 'test_helper'

class CodeBasedAuthorizationTest < ActiveSupport::TestCase
  def setup
    @person = FactoryBot.create(:person)
    User.current_user = @person.user
  end

  def teardown
    User.current_user = nil
  end

  # ===============================================
  # Investigation Tests
  # ===============================================

  test 'investigation auth_by_code with own code' do
    investigation = FactoryBot.create(:investigation, contributor: @person)
    code = nil

    disable_authorization_checks do
      code = SpecialAuthCode.create!(
        asset: investigation,
        code: SecureRandom.base64(30),
        expiration_date: Date.today + 7.days
      )
    end

    assert investigation.auth_by_code?(code.code), 'Investigation should be accessible with its own code'
  end

  test 'investigation auth_by_code does not check child study codes' do
    investigation = FactoryBot.create(:investigation, contributor: @person)
    study = FactoryBot.create(:study, investigation: investigation, contributor: @person)

    study_code = nil
    disable_authorization_checks do
      study_code = SpecialAuthCode.create!(
        asset: study,
        code: SecureRandom.base64(30),
        expiration_date: Date.today + 7.days
      )
    end

    refute investigation.auth_by_code?(study_code.code),
           'Investigation should NOT be accessible with child Study code (no upward propagation)'
  end

  test 'investigation auth_by_code does not check child assay codes' do
    investigation = FactoryBot.create(:investigation, contributor: @person)
    study = FactoryBot.create(:study, investigation: investigation, contributor: @person)
    assay = FactoryBot.create(:assay, study: study, contributor: @person)

    assay_code = nil
    disable_authorization_checks do
      assay_code = SpecialAuthCode.create!(
        asset: assay,
        code: SecureRandom.base64(30),
        expiration_date: Date.today + 7.days
      )
    end

    refute investigation.auth_by_code?(assay_code.code),
           'Investigation should NOT be accessible with grandchild Assay code (no upward propagation)'
  end

  test 'investigation auth_by_code with expired code' do
    investigation = FactoryBot.create(:investigation, contributor: @person)

    expired_code = nil
    disable_authorization_checks do
      expired_code = SpecialAuthCode.create!(
        asset: investigation,
        code: SecureRandom.base64(30),
        expiration_date: Date.yesterday
      )
    end

    refute investigation.auth_by_code?(expired_code.code),
           'Investigation should NOT be accessible with expired code'
  end

  # ===============================================
  # Study Tests
  # ===============================================

  test 'study auth_by_code with own code' do
    investigation = FactoryBot.create(:investigation, contributor: @person)
    study = FactoryBot.create(:study, investigation: investigation, contributor: @person)

    code = nil
    disable_authorization_checks do
      code = SpecialAuthCode.create!(
        asset: study,
        code: SecureRandom.base64(30),
        expiration_date: Date.today + 7.days
      )
    end

    assert study.auth_by_code?(code.code), 'Study should be accessible with its own code'
  end

  test 'study auth_by_code with parent investigation code' do
    investigation = FactoryBot.create(:investigation, contributor: @person)
    study = FactoryBot.create(:study, investigation: investigation, contributor: @person)

    inv_code = nil
    disable_authorization_checks do
      inv_code = SpecialAuthCode.create!(
        asset: investigation,
        code: SecureRandom.base64(30),
        expiration_date: Date.today + 7.days
      )
    end

    assert study.auth_by_code?(inv_code.code),
           'Study should be accessible with parent Investigation code (downward propagation)'
  end

  test 'study auth_by_code does not check child assay codes' do
    investigation = FactoryBot.create(:investigation, contributor: @person)
    study = FactoryBot.create(:study, investigation: investigation, contributor: @person)
    assay = FactoryBot.create(:assay, study: study, contributor: @person)

    assay_code = nil
    disable_authorization_checks do
      assay_code = SpecialAuthCode.create!(
        asset: assay,
        code: SecureRandom.base64(30),
        expiration_date: Date.today + 7.days
      )
    end

    refute study.auth_by_code?(assay_code.code),
           'Study should NOT be accessible with child Assay code (no upward propagation)'
  end

  # ===============================================
  # Assay Tests
  # ===============================================

  test 'assay auth_by_code with own code' do
    investigation = FactoryBot.create(:investigation, contributor: @person)
    study = FactoryBot.create(:study, investigation: investigation, contributor: @person)
    assay = FactoryBot.create(:assay, study: study, contributor: @person)

    code = nil
    disable_authorization_checks do
      code = SpecialAuthCode.create!(
        asset: assay,
        code: SecureRandom.base64(30),
        expiration_date: Date.today + 7.days
      )
    end

    assert assay.auth_by_code?(code.code), 'Assay should be accessible with its own code'
  end

  test 'assay auth_by_code with parent study code' do
    investigation = FactoryBot.create(:investigation, contributor: @person)
    study = FactoryBot.create(:study, investigation: investigation, contributor: @person)
    assay = FactoryBot.create(:assay, study: study, contributor: @person)

    study_code = nil
    disable_authorization_checks do
      study_code = SpecialAuthCode.create!(
        asset: study,
        code: SecureRandom.base64(30),
        expiration_date: Date.today + 7.days
      )
    end

    assert assay.auth_by_code?(study_code.code),
           'Assay should be accessible with parent Study code (downward propagation)'
  end

  test 'assay auth_by_code with grandparent investigation code' do
    investigation = FactoryBot.create(:investigation, contributor: @person)
    study = FactoryBot.create(:study, investigation: investigation, contributor: @person)
    assay = FactoryBot.create(:assay, study: study, contributor: @person)

    inv_code = nil
    disable_authorization_checks do
      inv_code = SpecialAuthCode.create!(
        asset: investigation,
        code: SecureRandom.base64(30),
        expiration_date: Date.today + 7.days
      )
    end

    assert assay.auth_by_code?(inv_code.code),
           'Assay should be accessible with grandparent Investigation code (downward propagation)'
  end

  # ===============================================
  # Asset Tests (DataFile, Model, SOP, etc.)
  # ===============================================

  test 'data_file auth_by_code with own code' do
    data_file = FactoryBot.create(:data_file, contributor: @person)

    code = nil
    disable_authorization_checks do
      code = SpecialAuthCode.create!(
        asset: data_file,
        code: SecureRandom.base64(30),
        expiration_date: Date.today + 7.days
      )
    end

    assert data_file.auth_by_code?(code.code), 'DataFile should be accessible with its own code'
  end

  test 'data_file auth_by_code with parent assay code' do
    investigation = FactoryBot.create(:investigation, contributor: @person)
    study = FactoryBot.create(:study, investigation: investigation, contributor: @person)
    assay = FactoryBot.create(:assay, study: study, contributor: @person)
    data_file = FactoryBot.create(:data_file, contributor: @person)

    disable_authorization_checks do
      assay.assay_assets.create(asset: data_file)
    end

    assay_code = nil
    disable_authorization_checks do
      assay_code = SpecialAuthCode.create!(
        asset: assay,
        code: SecureRandom.base64(30),
        expiration_date: Date.today + 7.days
      )
    end

    assert data_file.auth_by_code?(assay_code.code),
           'DataFile should be accessible with parent Assay code (downward propagation)'
  end

  test 'data_file auth_by_code with grandparent study code via assay' do
    investigation = FactoryBot.create(:investigation, contributor: @person)
    study = FactoryBot.create(:study, investigation: investigation, contributor: @person)
    assay = FactoryBot.create(:assay, study: study, contributor: @person)
    data_file = FactoryBot.create(:data_file, contributor: @person)

    disable_authorization_checks do
      assay.assay_assets.create(asset: data_file)
    end

    study_code = nil
    disable_authorization_checks do
      study_code = SpecialAuthCode.create!(
        asset: study,
        code: SecureRandom.base64(30),
        expiration_date: Date.today + 7.days
      )
    end

    assert data_file.auth_by_code?(study_code.code),
           'DataFile should be accessible with grandparent Study code via Assay (downward propagation)'
  end

  test 'data_file auth_by_code with great-grandparent investigation code via assay' do
    investigation = FactoryBot.create(:investigation, contributor: @person)
    study = FactoryBot.create(:study, investigation: investigation, contributor: @person)
    assay = FactoryBot.create(:assay, study: study, contributor: @person)
    data_file = FactoryBot.create(:data_file, contributor: @person)

    disable_authorization_checks do
      assay.assay_assets.create(asset: data_file)
    end

    inv_code = nil
    disable_authorization_checks do
      inv_code = SpecialAuthCode.create!(
        asset: investigation,
        code: SecureRandom.base64(30),
        expiration_date: Date.today + 7.days
      )
    end

    assert data_file.auth_by_code?(inv_code.code),
           'DataFile should be accessible with great-grandparent Investigation code via Assay (downward propagation)'
  end

  test 'model auth_by_code with parent assay code' do
    investigation = FactoryBot.create(:investigation, contributor: @person)
    study = FactoryBot.create(:study, investigation: investigation, contributor: @person)
    assay = FactoryBot.create(:assay, study: study, contributor: @person)
    model = FactoryBot.create(:model, contributor: @person)

    disable_authorization_checks do
      assay.assay_assets.create(asset: model)
    end

    assay_code = nil
    disable_authorization_checks do
      assay_code = SpecialAuthCode.create!(
        asset: assay,
        code: SecureRandom.base64(30),
        expiration_date: Date.today + 7.days
      )
    end

    assert model.auth_by_code?(assay_code.code),
           'Model should be accessible with parent Assay code (downward propagation)'
  end

  test 'sop auth_by_code with parent assay code' do
    investigation = FactoryBot.create(:investigation, contributor: @person)
    study = FactoryBot.create(:study, investigation: investigation, contributor: @person)
    assay = FactoryBot.create(:assay, study: study, contributor: @person)
    sop = FactoryBot.create(:sop, contributor: @person)

    disable_authorization_checks do
      assay.assay_assets.create(asset: sop)
    end

    assay_code = nil
    disable_authorization_checks do
      assay_code = SpecialAuthCode.create!(
        asset: assay,
        code: SecureRandom.base64(30),
        expiration_date: Date.today + 7.days
      )
    end

    assert sop.auth_by_code?(assay_code.code),
           'SOP should be accessible with parent Assay code (downward propagation)'
  end

  # ===============================================
  # Edge Cases and Complex Scenarios
  # ===============================================

  test 'asset with multiple parent assays - any parent code works' do
    investigation = FactoryBot.create(:investigation, contributor: @person)
    study = FactoryBot.create(:study, investigation: investigation, contributor: @person)
    assay1 = FactoryBot.create(:assay, study: study, contributor: @person)
    assay2 = FactoryBot.create(:assay, study: study, contributor: @person)
    data_file = FactoryBot.create(:data_file, contributor: @person)

    disable_authorization_checks do
      assay1.assay_assets.create(asset: data_file)
      assay2.assay_assets.create(asset: data_file)
    end

    assay1_code = nil
    disable_authorization_checks do
      assay1_code = SpecialAuthCode.create!(
        asset: assay1,
        code: SecureRandom.base64(30),
        expiration_date: Date.today + 7.days
      )
    end

    assert data_file.auth_by_code?(assay1_code.code),
           'DataFile should be accessible with any parent Assay code'
  end

  test 'orphaned assay without study does not crash' do
    assay = FactoryBot.create(:assay, study: nil, contributor: @person)

    fake_code = SecureRandom.base64(30)

    assert_nothing_raised do
      result = assay.auth_by_code?(fake_code)
      refute result, 'Orphaned Assay should return false for non-existent code'
    end
  end

  test 'orphaned study without investigation still checks own codes' do
    study = FactoryBot.create(:study, investigation: nil, contributor: @person)

    code = nil
    disable_authorization_checks do
      code = SpecialAuthCode.create!(
        asset: study,
        code: SecureRandom.base64(30),
        expiration_date: Date.today + 7.days
      )
    end

    assert study.auth_by_code?(code.code),
           'Orphaned Study should still be accessible with its own code'
  end

  test 'invalid code returns false' do
    investigation = FactoryBot.create(:investigation, contributor: @person)

    fake_code = SecureRandom.base64(30)

    refute investigation.auth_by_code?(fake_code),
           'Resource should not be accessible with invalid code'
  end

  test 'nil code returns false' do
    investigation = FactoryBot.create(:investigation, contributor: @person)

    refute investigation.auth_by_code?(nil),
           'Resource should not be accessible with nil code'
  end

  test 'empty code returns false' do
    investigation = FactoryBot.create(:investigation, contributor: @person)

    refute investigation.auth_by_code?(''),
           'Resource should not be accessible with empty code'
  end

  # ===============================================
  # Complete Hierarchy Test
  # ===============================================

  test 'complete ISA hierarchy with investigation code grants access to all levels' do
    investigation = FactoryBot.create(:investigation, contributor: @person)
    study = FactoryBot.create(:study, investigation: investigation, contributor: @person)
    assay = FactoryBot.create(:assay, study: study, contributor: @person)
    data_file = FactoryBot.create(:data_file, contributor: @person)

    disable_authorization_checks do
      assay.assay_assets.create(asset: data_file)
    end

    inv_code = nil
    disable_authorization_checks do
      inv_code = SpecialAuthCode.create!(
        asset: investigation,
        code: SecureRandom.base64(30),
        expiration_date: Date.today + 7.days
      )
    end

    # Investigation code should grant access to all descendants
    assert investigation.auth_by_code?(inv_code.code), 'Investigation accessible with its own code'
    assert study.auth_by_code?(inv_code.code), 'Study accessible with Investigation code'
    assert assay.auth_by_code?(inv_code.code), 'Assay accessible with Investigation code'
    assert data_file.auth_by_code?(inv_code.code), 'DataFile accessible with Investigation code'
  end

  test 'study code does not grant access upward to investigation' do
    investigation = FactoryBot.create(:investigation, contributor: @person)
    study = FactoryBot.create(:study, investigation: investigation, contributor: @person)
    assay = FactoryBot.create(:assay, study: study, contributor: @person)

    study_code = nil
    disable_authorization_checks do
      study_code = SpecialAuthCode.create!(
        asset: study,
        code: SecureRandom.base64(30),
        expiration_date: Date.today + 7.days
      )
    end

    # Study code should grant access to study and descendants, but NOT investigation
    refute investigation.auth_by_code?(study_code.code), 'Investigation NOT accessible with Study code'
    assert study.auth_by_code?(study_code.code), 'Study accessible with its own code'
    assert assay.auth_by_code?(study_code.code), 'Assay accessible with Study code'
  end

  test 'assay code does not grant access upward to study or investigation' do
    investigation = FactoryBot.create(:investigation, contributor: @person)
    study = FactoryBot.create(:study, investigation: investigation, contributor: @person)
    assay = FactoryBot.create(:assay, study: study, contributor: @person)
    data_file = FactoryBot.create(:data_file, contributor: @person)

    disable_authorization_checks do
      assay.assay_assets.create(asset: data_file)
    end

    assay_code = nil
    disable_authorization_checks do
      assay_code = SpecialAuthCode.create!(
        asset: assay,
        code: SecureRandom.base64(30),
        expiration_date: Date.today + 7.days
      )
    end

    # Assay code should grant access to assay and descendants, but NOT parents
    refute investigation.auth_by_code?(assay_code.code), 'Investigation NOT accessible with Assay code'
    refute study.auth_by_code?(assay_code.code), 'Study NOT accessible with Assay code'
    assert assay.auth_by_code?(assay_code.code), 'Assay accessible with its own code'
    assert data_file.auth_by_code?(assay_code.code), 'DataFile accessible with Assay code'
  end
end

