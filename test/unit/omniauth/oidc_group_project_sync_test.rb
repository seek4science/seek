require 'test_helper'

class OidcGroupProjectSyncTest < ActiveSupport::TestCase
  def setup
    @institution = FactoryBot.create(:institution)
    @person = FactoryBot.create(:person, institution: @institution)
  end

  def auth_with_claim(claim_path, value)
    raw = {}
    parts = claim_path.split('.')
    cursor = raw
    parts[0..-2].each do |part|
      cursor[part] = {}
      cursor = cursor[part]
    end
    cursor[parts.last] = value

    OmniAuth::AuthHash.new(
      provider: 'oidc',
      uid: 'oidc-user-1',
      info: { email: @person.email, first_name: @person.first_name, last_name: @person.last_name },
      extra: { raw_info: raw }
    )
  end

  test 'extract_claim_value supports nested paths' do
    raw = { 'realm_access' => { 'roles' => %w[alpha beta] } }
    assert_equal %w[alpha beta], Seek::Omniauth::OidcGroupProjectSync.extract_claim_value(raw, 'realm_access.roles')
  end

  test 'normalize_groups handles array string and scalar' do
    assert_equal %w[a b], Seek::Omniauth::OidcGroupProjectSync.normalize_groups(%w[a b])
    assert_equal %w[a b c], Seek::Omniauth::OidcGroupProjectSync.normalize_groups('a, b;c')
    assert_equal %w[solo], Seek::Omniauth::OidcGroupProjectSync.normalize_groups('solo')
    assert_equal [], Seek::Omniauth::OidcGroupProjectSync.normalize_groups(nil)
  end

  test 'project_title_for uses last URN segment' do
    assert_equal 'my-project',
                 Seek::Omniauth::OidcGroupProjectSync.project_title_for('urn:mace:example.org:group:my-project')
    assert_equal 'plain', Seek::Omniauth::OidcGroupProjectSync.project_title_for('plain')
  end

  test 'disabled feature does nothing' do
    auth = auth_with_claim('entitlement', ['new-group-project'])
    with_config_value(:omniauth_oidc_groups_enabled, false) do
      assert_no_difference('Project.count') do
        Seek::Omniauth::OidcGroupProjectSync.call(person: @person, auth: auth)
      end
    end
  end

  test 'creates project and makes user administrator' do
    auth = auth_with_claim('entitlement', ['brand-new-oidc-project'])
    with_config_values(omniauth_oidc_groups_enabled: true,
                       omniauth_oidc_groups_claim: 'entitlement',
                       omniauth_oidc_groups_institution_id: @institution.id) do
      assert_difference('Project.count', 1) do
        Seek::Omniauth::OidcGroupProjectSync.call(person: @person, auth: auth)
      end
    end

    project = Project.find_by(title: 'brand-new-oidc-project')
    assert project
    @person.reload
    assert @person.member_of?(project)
    assert @person.is_project_administrator?(project)
  end

  test 'existing project with admin makes user member only' do
    project = FactoryBot.create(:project, title: 'existing-oidc-project')
    admin = FactoryBot.create(:project_administrator, project: project)
    assert admin.is_project_administrator?(project)

    auth = auth_with_claim('entitlement', ['existing-oidc-project'])
    with_config_values(omniauth_oidc_groups_enabled: true,
                       omniauth_oidc_groups_claim: 'entitlement',
                       omniauth_oidc_groups_institution_id: @institution.id) do
      assert_no_difference('Project.count') do
        Seek::Omniauth::OidcGroupProjectSync.call(person: @person, auth: auth)
      end
    end

    @person.reload
    project.reload
    assert @person.member_of?(project)
    refute @person.is_project_administrator?(project)
    assert admin.is_project_administrator?(project)
  end

  test 'existing project with no admin promotes user to administrator' do
    project = FactoryBot.create(:project, title: 'orphan-oidc-project')
    assert_empty project.project_administrators

    auth = auth_with_claim('entitlement', ['orphan-oidc-project'])
    with_config_values(omniauth_oidc_groups_enabled: true,
                       omniauth_oidc_groups_claim: 'entitlement',
                       omniauth_oidc_groups_institution_id: @institution.id) do
      Seek::Omniauth::OidcGroupProjectSync.call(person: @person, auth: auth)
    end

    @person.reload
    project.reload
    assert @person.member_of?(project)
    assert @person.is_project_administrator?(project)
  end

  test 'empty claim is a no-op' do
    auth = auth_with_claim('entitlement', [])
    with_config_values(omniauth_oidc_groups_enabled: true,
                       omniauth_oidc_groups_claim: 'entitlement') do
      assert_no_difference('Project.count') do
        Seek::Omniauth::OidcGroupProjectSync.call(person: @person, auth: auth)
      end
    end
  end

  test 'sync is idempotent for existing membership' do
    auth = auth_with_claim('entitlement', ['idempotent-oidc-project'])
    with_config_values(omniauth_oidc_groups_enabled: true,
                       omniauth_oidc_groups_claim: 'entitlement',
                       omniauth_oidc_groups_institution_id: @institution.id) do
      Seek::Omniauth::OidcGroupProjectSync.call(person: @person, auth: auth)
      assert_no_difference(['Project.count', 'GroupMembership.count']) do
        Seek::Omniauth::OidcGroupProjectSync.call(person: @person, auth: auth)
      end
    end

    @person.reload
    project = Project.find_by!(title: 'idempotent-oidc-project')
    assert @person.member_of?(project)
    assert @person.is_project_administrator?(project)
  end
end
