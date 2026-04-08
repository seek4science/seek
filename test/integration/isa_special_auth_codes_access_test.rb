require 'test_helper'

class IsaSpecialAuthCodesAccessTest < ActionDispatch::IntegrationTest
  # ===============================================
  # Investigation Tests
  # ===============================================

  test 'manager can create temporary link for investigation' do
    user = FactoryBot.create(:user, login: 'test_manager')
    investigation = nil

    User.with_current_user(user) do
      investigation = FactoryBot.create(:investigation,
        policy: FactoryBot.create(:private_policy),
        contributor: user.person
      )
    end

    post '/session', params: { login: 'test_manager', password: user.password }

    # Check manage page shows temporary links section
    get "/investigations/#{investigation.id}/manage"
    assert_response :success
    assert_select 'form div#temporary_links'
  end

  test 'manager can see temporary link on investigation show page' do
    user = FactoryBot.create(:user)
    investigation = nil

    User.with_current_user(user) do
      investigation = FactoryBot.create(:investigation,
        policy: FactoryBot.create(:private_policy),
        contributor: user.person
      )

      disable_authorization_checks do
        investigation.special_auth_codes << FactoryBot.create(:special_auth_code, asset: investigation)
      end
    end

    post '/session', params: { login: user.login, password: user.password }
    get "/investigations/#{investigation.id}"

    assert_response :success
    code = investigation.special_auth_codes.first.code
    url = polymorphic_url(investigation, code: code)
    assert_select '#special-auth-code input[value=?]', url, count: 1
  end

  test 'anonymous user can view investigation with valid code' do
    investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:private_policy))

    disable_authorization_checks do
      User.with_current_user(investigation.contributor.user) do
        investigation.special_auth_codes << FactoryBot.create(:special_auth_code, asset: investigation)
      end
    end

    code = CGI.escape(investigation.special_auth_codes.first.code)
    get "/investigations/#{investigation.id}?code=#{code}"
    assert_response :success
    assert_select 'h1', text: investigation.title
  end

  test 'anonymous user cannot view investigation without code' do
    investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:private_policy))

    get "/investigations/#{investigation.id}"
    assert_response :forbidden
  end

  test 'anonymous user cannot view investigation with expired code' do
    investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:private_policy))

    auth_code = User.with_current_user(investigation.contributor.user) do
      FactoryBot.create(:special_auth_code,
        expiration_date: (Time.now - 1.days),
        asset: investigation
      )
    end

    code = CGI.escape(auth_code.code)
    get "/investigations/#{investigation.id}?code=#{code}"
    assert_response :forbidden
  end

  test 'investigation code grants access to child studies' do
    investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:private_policy))
    study = FactoryBot.create(:study,
      investigation: investigation,
      policy: FactoryBot.create(:private_policy),
      contributor: investigation.contributor
    )

    auth_code = User.with_current_user(investigation.contributor.user) do
      FactoryBot.create(:special_auth_code,
        expiration_date: (Time.now + 1.days),
        asset: investigation
      )
    end

    code = CGI.escape(auth_code.code)

    # Can access investigation
    get "/investigations/#{investigation.id}?code=#{code}"
    assert_response :success

    # Can also access child study with same code
    get "/studies/#{study.id}?code=#{code}"
    assert_response :success
  end

  test 'investigation code grants access to child assays' do
    investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:private_policy))
    study = FactoryBot.create(:study,
      investigation: investigation,
      policy: FactoryBot.create(:private_policy),
      contributor: investigation.contributor
    )
    assay = FactoryBot.create(:assay,
      study: study,
      policy: FactoryBot.create(:private_policy),
      contributor: investigation.contributor
    )

    auth_code = User.with_current_user(investigation.contributor.user) do
      FactoryBot.create(:special_auth_code,
        expiration_date: (Time.now + 1.days),
        asset: investigation
      )
    end

    code = CGI.escape(auth_code.code)

    # Can access assay with investigation code
    get "/assays/#{assay.id}?code=#{code}"
    assert_response :success
  end

  test 'investigation code grants access to associated assets' do
    investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:private_policy))
    study = FactoryBot.create(:study,
      investigation: investigation,
      policy: FactoryBot.create(:private_policy),
      contributor: investigation.contributor
    )
    assay = FactoryBot.create(:assay,
      study: study,
      policy: FactoryBot.create(:private_policy),
      contributor: investigation.contributor
    )
    data_file = FactoryBot.create(:data_file,
      policy: FactoryBot.create(:private_policy),
      contributor: investigation.contributor
    )

    disable_authorization_checks do
      assay.assay_assets.create(asset: data_file)
    end

    auth_code = User.with_current_user(investigation.contributor.user) do
      FactoryBot.create(:special_auth_code,
        expiration_date: (Time.now + 1.days),
        asset: investigation
      )
    end

    code = CGI.escape(auth_code.code)

    # Can access data file with investigation code
    get "/data_files/#{data_file.id}?code=#{code}"
    assert_response :success
  end

  # ===============================================
  # Study Tests
  # ===============================================

  test 'manager can create temporary link for study' do
    user = FactoryBot.create(:user, login: 'test_manager')
    investigation = nil
    study = nil

    User.with_current_user(user) do
      investigation = FactoryBot.create(:investigation, contributor: user.person)
      study = FactoryBot.create(:study,
        investigation: investigation,
        policy: FactoryBot.create(:private_policy),
        contributor: user.person
      )
    end

    post '/session', params: { login: 'test_manager', password: user.password }

    # Check manage page shows temporary links section
    get "/studies/#{study.id}/manage"
    assert_response :success
    assert_select 'form div#temporary_links'
  end

  test 'anonymous user can view study with valid code' do
    investigation = FactoryBot.create(:investigation)
    study = FactoryBot.create(:study,
      investigation: investigation,
      policy: FactoryBot.create(:private_policy)
    )

    disable_authorization_checks do
      User.with_current_user(study.contributor.user) do
        study.special_auth_codes << FactoryBot.create(:special_auth_code, asset: study)
      end
    end

    code = CGI.escape(study.special_auth_codes.first.code)
    get "/studies/#{study.id}?code=#{code}"
    assert_response :success
    assert_select 'h1', text: study.title
  end

  test 'anonymous user can view study with parent investigation code' do
    investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:private_policy))
    study = FactoryBot.create(:study,
      investigation: investigation,
      policy: FactoryBot.create(:private_policy),
      contributor: investigation.contributor
    )

    auth_code = User.with_current_user(investigation.contributor.user) do
      FactoryBot.create(:special_auth_code,
        expiration_date: (Time.now + 1.days),
        asset: investigation
      )
    end

    code = CGI.escape(auth_code.code)

    # Can access study with investigation code
    get "/studies/#{study.id}?code=#{code}"
    assert_response :success
  end

  test 'study code grants access to child assays' do
    investigation = FactoryBot.create(:investigation)
    study = FactoryBot.create(:study,
      investigation: investigation,
      policy: FactoryBot.create(:private_policy)
    )
    assay = FactoryBot.create(:assay,
      study: study,
      policy: FactoryBot.create(:private_policy),
      contributor: study.contributor
    )

    auth_code = User.with_current_user(study.contributor.user) do
      FactoryBot.create(:special_auth_code,
        expiration_date: (Time.now + 1.days),
        asset: study
      )
    end

    code = CGI.escape(auth_code.code)

    # Can access study
    get "/studies/#{study.id}?code=#{code}"
    assert_response :success

    # Can also access child assay with same code
    get "/assays/#{assay.id}?code=#{code}"
    assert_response :success
  end

  test 'study code grants access to associated assets' do
    investigation = FactoryBot.create(:investigation)
    study = FactoryBot.create(:study,
      investigation: investigation,
      policy: FactoryBot.create(:private_policy)
    )
    assay = FactoryBot.create(:assay,
      study: study,
      policy: FactoryBot.create(:private_policy),
      contributor: study.contributor
    )
    data_file = FactoryBot.create(:data_file,
      policy: FactoryBot.create(:private_policy),
      contributor: study.contributor
    )

    disable_authorization_checks do
      assay.assay_assets.create(asset: data_file)
    end

    auth_code = User.with_current_user(study.contributor.user) do
      FactoryBot.create(:special_auth_code,
        expiration_date: (Time.now + 1.days),
        asset: study
      )
    end

    code = CGI.escape(auth_code.code)

    # Can access data file with study code
    get "/data_files/#{data_file.id}?code=#{code}"
    assert_response :success
  end

  test 'study code does not grant access to parent investigation' do
    investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:private_policy))
    study = FactoryBot.create(:study,
      investigation: investigation,
      policy: FactoryBot.create(:private_policy),
      contributor: investigation.contributor
    )

    auth_code = User.with_current_user(study.contributor.user) do
      FactoryBot.create(:special_auth_code,
        expiration_date: (Time.now + 1.days),
        asset: study
      )
    end

    code = CGI.escape(auth_code.code)

    # Cannot access parent investigation with study code (no upward propagation)
    get "/investigations/#{investigation.id}?code=#{code}"
    assert_response :forbidden
  end

  # ===============================================
  # Assay Tests
  # ===============================================

  test 'manager can create temporary link for assay' do
    user = FactoryBot.create(:user, login: 'test_manager')
    investigation = nil
    study = nil
    assay = nil

    User.with_current_user(user) do
      investigation = FactoryBot.create(:investigation, contributor: user.person)
      study = FactoryBot.create(:study, investigation: investigation, contributor: user.person)
      assay = FactoryBot.create(:assay,
        study: study,
        policy: FactoryBot.create(:private_policy),
        contributor: user.person
      )
    end

    post '/session', params: { login: 'test_manager', password: user.password }

    # Check manage page shows temporary links section
    get "/assays/#{assay.id}/manage"
    assert_response :success
    assert_select 'form div#temporary_links'
  end

  test 'anonymous user can view assay with valid code' do
    investigation = FactoryBot.create(:investigation)
    study = FactoryBot.create(:study, investigation: investigation)
    assay = FactoryBot.create(:assay,
      study: study,
      policy: FactoryBot.create(:private_policy)
    )

    disable_authorization_checks do
      User.with_current_user(assay.contributor.user) do
        assay.special_auth_codes << FactoryBot.create(:special_auth_code, asset: assay)
      end
    end

    code = CGI.escape(assay.special_auth_codes.first.code)
    get "/assays/#{assay.id}?code=#{code}"
    assert_response :success
    assert_select 'h1', text: assay.title
  end

  test 'anonymous user can download data files associated with assay using assay code' do
    investigation = FactoryBot.create(:investigation)
    study = FactoryBot.create(:study, investigation: investigation)
    assay = FactoryBot.create(:assay,
      study: study,
      policy: FactoryBot.create(:private_policy)
    )
    data_file = FactoryBot.create(:data_file,
      policy: FactoryBot.create(:private_policy),
      contributor: assay.contributor
    )

    disable_authorization_checks do
      assay.assay_assets.create(asset: data_file)
    end

    auth_code = User.with_current_user(assay.contributor.user) do
      FactoryBot.create(:special_auth_code,
        expiration_date: (Time.now + 1.days),
        asset: assay
      )
    end

    code = CGI.escape(auth_code.code)

    # Can access data file with assay code
    get "/data_files/#{data_file.id}?code=#{code}"
    assert_response :success

    # Can download data file
    get "/data_files/#{data_file.id}/content_blobs/#{data_file.content_blob.id}/download?code=#{code}"
    assert_response :success
  end

  test 'anonymous user can access SOPs associated with assay using assay code' do
    investigation = FactoryBot.create(:investigation)
    study = FactoryBot.create(:study, investigation: investigation)
    assay = FactoryBot.create(:assay,
      study: study,
      policy: FactoryBot.create(:private_policy)
    )
    sop = FactoryBot.create(:sop,
      policy: FactoryBot.create(:private_policy),
      contributor: assay.contributor
    )

    disable_authorization_checks do
      assay.assay_assets.create(asset: sop)
    end

    auth_code = User.with_current_user(assay.contributor.user) do
      FactoryBot.create(:special_auth_code,
        expiration_date: (Time.now + 1.days),
        asset: assay
      )
    end

    code = CGI.escape(auth_code.code)

    # Can access SOP with assay code
    get "/sops/#{sop.id}?code=#{code}"
    assert_response :success
  end

  test 'anonymous user can access models associated with assay using assay code' do
    investigation = FactoryBot.create(:investigation)
    study = FactoryBot.create(:study, investigation: investigation)
    assay = FactoryBot.create(:assay,
      study: study,
      policy: FactoryBot.create(:private_policy)
    )
    model = FactoryBot.create(:model,
      policy: FactoryBot.create(:private_policy),
      contributor: assay.contributor
    )

    disable_authorization_checks do
      assay.assay_assets.create(asset: model)
    end

    auth_code = User.with_current_user(assay.contributor.user) do
      FactoryBot.create(:special_auth_code,
        expiration_date: (Time.now + 1.days),
        asset: assay
      )
    end

    code = CGI.escape(auth_code.code)

    # Can access model with assay code
    get "/models/#{model.id}?code=#{code}"
    assert_response :success
  end

  test 'anonymous user can access documents associated with assay using assay code' do
    investigation = FactoryBot.create(:investigation)
    study = FactoryBot.create(:study, investigation: investigation)
    assay = FactoryBot.create(:assay,
      study: study,
      policy: FactoryBot.create(:private_policy)
    )
    document = FactoryBot.create(:document,
      policy: FactoryBot.create(:private_policy),
      contributor: assay.contributor
    )

    disable_authorization_checks do
      assay.assay_assets.create(asset: document)
    end

    auth_code = User.with_current_user(assay.contributor.user) do
      FactoryBot.create(:special_auth_code,
        expiration_date: (Time.now + 1.days),
        asset: assay
      )
    end

    code = CGI.escape(auth_code.code)

    # Can access document with assay code
    get "/documents/#{document.id}?code=#{code}"
    assert_response :success
  end

  test 'assay code does not grant access to parent study' do
    investigation = FactoryBot.create(:investigation)
    study = FactoryBot.create(:study,
      investigation: investigation,
      policy: FactoryBot.create(:private_policy)
    )
    assay = FactoryBot.create(:assay,
      study: study,
      policy: FactoryBot.create(:private_policy),
      contributor: study.contributor
    )

    auth_code = User.with_current_user(assay.contributor.user) do
      FactoryBot.create(:special_auth_code,
        expiration_date: (Time.now + 1.days),
        asset: assay
      )
    end

    code = CGI.escape(auth_code.code)

    # Cannot access parent study with assay code (no upward propagation)
    get "/studies/#{study.id}?code=#{code}"
    assert_response :forbidden
  end

  test 'assay code does not grant access to grandparent investigation' do
    investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:private_policy))
    study = FactoryBot.create(:study,
      investigation: investigation,
      policy: FactoryBot.create(:private_policy),
      contributor: investigation.contributor
    )
    assay = FactoryBot.create(:assay,
      study: study,
      policy: FactoryBot.create(:private_policy),
      contributor: investigation.contributor
    )

    auth_code = User.with_current_user(assay.contributor.user) do
      FactoryBot.create(:special_auth_code,
        expiration_date: (Time.now + 1.days),
        asset: assay
      )
    end

    code = CGI.escape(auth_code.code)

    # Cannot access grandparent investigation with assay code (no upward propagation)
    get "/investigations/#{investigation.id}?code=#{code}"
    assert_response :forbidden
  end

  # ===============================================
  # Code Expiration Tests
  # ===============================================

  test 'valid investigation code allows access until expiration date' do
    investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:private_policy))

    auth_code = User.with_current_user(investigation.contributor.user) do
      FactoryBot.create(:special_auth_code,
        expiration_date: (Time.now + 7.days),
        asset: investigation
      )
    end

    code = CGI.escape(auth_code.code)

    # Can access with valid code
    get "/investigations/#{investigation.id}?code=#{code}"
    assert_response :success
  end

  test 'expired investigation code denies access' do
    investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:private_policy))

    auth_code = User.with_current_user(investigation.contributor.user) do
      FactoryBot.create(:special_auth_code,
        expiration_date: (Time.now - 1.days),
        asset: investigation
      )
    end

    code = CGI.escape(auth_code.code)

    # Cannot access with expired code
    get "/investigations/#{investigation.id}?code=#{code}"
    assert_response :forbidden
  end

  test 'manager can revoke investigation codes' do
    user = FactoryBot.create(:user)
    investigation = nil

    User.with_current_user(user) do
      investigation = FactoryBot.create(:investigation,
        policy: FactoryBot.create(:private_policy),
        contributor: user.person
      )
    end

    auth_code = User.with_current_user(user) do
      FactoryBot.create(:special_auth_code,
        expiration_date: (Time.now + 7.days),
        asset: investigation
      )
    end

    code = CGI.escape(auth_code.code)

    # Can access with valid code
    get "/investigations/#{investigation.id}?code=#{code}"
    assert_response :success

    # Manager revokes code by setting expiration to past
    User.with_current_user(user) do
      disable_authorization_checks do
        auth_code.expiration_date = Time.now - 1.days
        auth_code.save!
      end
    end

    # Cannot access with revoked code
    get "/investigations/#{investigation.id}?code=#{code}"
    assert_response :forbidden
  end

  # ===============================================
  # Nested Access Tests
  # ===============================================

  test 'investigation code grants access to all studies and assays in hierarchy' do
    investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:private_policy))
    study1 = FactoryBot.create(:study,
      investigation: investigation,
      policy: FactoryBot.create(:private_policy),
      contributor: investigation.contributor
    )
    study2 = FactoryBot.create(:study,
      investigation: investigation,
      policy: FactoryBot.create(:private_policy),
      contributor: investigation.contributor
    )
    assay1 = FactoryBot.create(:assay,
      study: study1,
      policy: FactoryBot.create(:private_policy),
      contributor: investigation.contributor
    )
    assay2 = FactoryBot.create(:assay,
      study: study2,
      policy: FactoryBot.create(:private_policy),
      contributor: investigation.contributor
    )

    auth_code = User.with_current_user(investigation.contributor.user) do
      FactoryBot.create(:special_auth_code,
        expiration_date: (Time.now + 1.days),
        asset: investigation
      )
    end

    code = CGI.escape(auth_code.code)

    # Can access investigation
    get "/investigations/#{investigation.id}?code=#{code}"
    assert_response :success

    # Can access all studies
    get "/studies/#{study1.id}?code=#{code}"
    assert_response :success

    get "/studies/#{study2.id}?code=#{code}"
    assert_response :success

    # Can access all assays
    get "/assays/#{assay1.id}?code=#{code}"
    assert_response :success

    get "/assays/#{assay2.id}?code=#{code}"
    assert_response :success
  end

  test 'study code grants access to all its assays but not sibling studies' do
    investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:private_policy))
    study1 = FactoryBot.create(:study,
      investigation: investigation,
      policy: FactoryBot.create(:private_policy),
      contributor: investigation.contributor
    )
    study2 = FactoryBot.create(:study,
      investigation: investigation,
      policy: FactoryBot.create(:private_policy),
      contributor: investigation.contributor
    )
    assay1 = FactoryBot.create(:assay,
      study: study1,
      policy: FactoryBot.create(:private_policy),
      contributor: investigation.contributor
    )
    assay2 = FactoryBot.create(:assay,
      study: study1,
      policy: FactoryBot.create(:private_policy),
      contributor: investigation.contributor
    )

    auth_code = User.with_current_user(study1.contributor.user) do
      FactoryBot.create(:special_auth_code,
        expiration_date: (Time.now + 1.days),
        asset: study1
      )
    end

    code = CGI.escape(auth_code.code)

    # Can access study1
    get "/studies/#{study1.id}?code=#{code}"
    assert_response :success

    # Can access study1's assays
    get "/assays/#{assay1.id}?code=#{code}"
    assert_response :success

    get "/assays/#{assay2.id}?code=#{code}"
    assert_response :success

    # Cannot access sibling study2
    get "/studies/#{study2.id}?code=#{code}"
    assert_response :forbidden
  end

  test 'assay code only grants access to that assay and its assets' do
    investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:private_policy))
    study = FactoryBot.create(:study,
      investigation: investigation,
      policy: FactoryBot.create(:private_policy),
      contributor: investigation.contributor
    )
    assay1 = FactoryBot.create(:assay,
      study: study,
      policy: FactoryBot.create(:private_policy),
      contributor: investigation.contributor
    )
    assay2 = FactoryBot.create(:assay,
      study: study,
      policy: FactoryBot.create(:private_policy),
      contributor: investigation.contributor
    )
    data_file = FactoryBot.create(:data_file,
      policy: FactoryBot.create(:private_policy),
      contributor: investigation.contributor
    )

    disable_authorization_checks do
      assay1.assay_assets.create(asset: data_file)
    end

    auth_code = User.with_current_user(assay1.contributor.user) do
      FactoryBot.create(:special_auth_code,
        expiration_date: (Time.now + 1.days),
        asset: assay1
      )
    end

    code = CGI.escape(auth_code.code)

    # Can access assay1
    get "/assays/#{assay1.id}?code=#{code}"
    assert_response :success

    # Can access assay1's data file
    get "/data_files/#{data_file.id}?code=#{code}"
    assert_response :success

    # Cannot access sibling assay2
    get "/assays/#{assay2.id}?code=#{code}"
    assert_response :forbidden

    # Cannot access parent study
    get "/studies/#{study.id}?code=#{code}"
    assert_response :forbidden

    # Cannot access grandparent investigation
    get "/investigations/#{investigation.id}?code=#{code}"
    assert_response :forbidden
  end

  # ===============================================
  # Public Item with Private Children
  # ===============================================

  test 'public investigation with code grants access to private children' do
    investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:public_policy))
    study = FactoryBot.create(:study,
      investigation: investigation,
      policy: FactoryBot.create(:private_policy),
      contributor: investigation.contributor
    )

    auth_code = User.with_current_user(investigation.contributor.user) do
      FactoryBot.create(:special_auth_code,
        expiration_date: (Time.now + 1.days),
        asset: investigation
      )
    end

    code = CGI.escape(auth_code.code)

    # Can access investigation (public anyway)
    get "/investigations/#{investigation.id}?code=#{code}"
    assert_response :success

    # Can access private study with investigation code
    get "/studies/#{study.id}?code=#{code}"
    assert_response :success
  end
end

