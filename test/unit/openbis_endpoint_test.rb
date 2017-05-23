require 'test_helper'
require 'openbis_test_helper'

class OpenbisEndpointTest < ActiveSupport::TestCase
  def setup
    mock_openbis_calls
  end

  test 'validation' do
    project = Factory(:project)
    endpoint = OpenbisEndpoint.new project: project, username: 'fred', password: '12345',
                                   web_endpoint: 'http://my-openbis.org/openbis',
                                   as_endpoint: 'http://my-openbis.org/openbis',
                                   dss_endpoint: 'http://my-openbis.org/openbis',
                                   space_perm_id: 'mmmm',
                                   refresh_period_mins: 60

    assert endpoint.valid?
    endpoint.username = nil
    refute endpoint.valid?
    endpoint.username = 'fred'
    assert endpoint.valid?

    endpoint.password = nil
    refute endpoint.valid?
    endpoint.password = '12345'
    assert endpoint.valid?

    endpoint.space_perm_id = nil
    refute endpoint.valid?
    endpoint.space_perm_id = 'mmmmm'
    assert endpoint.valid?

    endpoint.as_endpoint = nil
    refute endpoint.valid?
    endpoint.as_endpoint = 'fish'
    refute endpoint.valid?
    endpoint.as_endpoint = 'http://my-openbis.org/openbis'
    assert endpoint.valid?

    endpoint.dss_endpoint = nil
    refute endpoint.valid?
    endpoint.dss_endpoint = 'fish'
    refute endpoint.valid?
    endpoint.dss_endpoint = 'http://my-openbis.org/openbis'
    assert endpoint.valid?

    endpoint.web_endpoint = nil
    refute endpoint.valid?
    endpoint.web_endpoint = 'fish'
    refute endpoint.valid?
    endpoint.web_endpoint = 'http://my-openbis.org/openbis'
    assert endpoint.valid?

    endpoint.refresh_period_mins = nil
    refute endpoint.valid?
    endpoint.refresh_period_mins = 0
    refute endpoint.valid?
    endpoint.refresh_period_mins = 10
    refute endpoint.valid?
    endpoint.refresh_period_mins = 60
    assert endpoint.valid?

    endpoint.project = nil
    refute endpoint.valid?
    endpoint.project = Factory(:project)
    assert endpoint.valid?

    endpoint.policy = nil
    refute endpoint.valid?
  end

  test 'default refresh period' do
    assert_equal 120, OpenbisEndpoint.new.refresh_period_mins
  end

  test 'validates uniqueness' do
    endpoint = Factory(:openbis_endpoint)
    endpoint2 = Factory.build(:openbis_endpoint)
    assert endpoint.valid? # different project
    endpoint2 = Factory.build(:openbis_endpoint, project: endpoint.project)
    refute endpoint2.valid?
    endpoint2.as_endpoint = 'http://fish.com'
    assert endpoint2.valid?
    endpoint2.as_endpoint = endpoint.as_endpoint
    refute endpoint2.valid?
    endpoint2.dss_endpoint = 'http://fish.com'
    assert endpoint2.valid?
  end

  test 'default policy' do
    endpoint = OpenbisEndpoint.new
    refute_nil endpoint.policy
  end

  test 'link to project' do
    pa = Factory(:project_administrator)
    project = pa.projects.first
    User.with_current_user(pa.user) do
      with_config_value :openbis_enabled, true do
        endpoint = OpenbisEndpoint.create project: project, username: 'fred', password: '12345', as_endpoint: 'http://my-openbis.org/openbis', dss_endpoint: 'http://my-openbis.org/openbis', web_endpoint: 'http://my-openbis.org/openbis', space_perm_id: 'aaa'
        endpoint2 = OpenbisEndpoint.create project: project, username: 'fred', password: '12345', as_endpoint: 'http://my-openbis.org/openbis', dss_endpoint: 'http://my-openbis.org/openbis', web_endpoint: 'http://my-openbis.org/openbis', space_perm_id: 'bbb'
        endpoint.save!
        endpoint2.save!
        project.reload
        assert_equal [endpoint, endpoint2].sort, project.openbis_endpoints.sort
      end
    end
  end

  test 'can_create' do
    User.with_current_user(Factory(:project_administrator).user) do
      with_config_value :openbis_enabled, true do
        assert OpenbisEndpoint.can_create?
      end

      with_config_value :openbis_enabled, false do
        refute OpenbisEndpoint.can_create?
      end
    end

    User.with_current_user(Factory(:person).user) do
      with_config_value :openbis_enabled, true do
        refute OpenbisEndpoint.can_create?
      end

      with_config_value :openbis_enabled, false do
        refute OpenbisEndpoint.can_create?
      end
    end

    User.with_current_user(nil) do
      with_config_value :openbis_enabled, true do
        refute OpenbisEndpoint.can_create?
      end

      with_config_value :openbis_enabled, false do
        refute OpenbisEndpoint.can_create?
      end
    end
  end

  test 'can_delete?' do
    person = Factory(:person)
    ep = Factory(:openbis_endpoint, project: person.projects.first)
    refute ep.can_delete?(person.user)
    User.with_current_user(person.user) do
      refute ep.can_delete?
    end

    pa = Factory(:project_administrator)
    ep = Factory(:openbis_endpoint, project: pa.projects.first)
    assert ep.can_delete?(pa.user)
    User.with_current_user(pa.user) do
      assert ep.can_delete?
    end

    another_pa = Factory(:project_administrator)
    refute ep.can_delete?(another_pa.user)
    User.with_current_user(another_pa.user) do
      refute ep.can_delete?
    end

    # cannot delete if linked
    # first check another linked endpoint doesn't prevent delete
    refute_nil openbis_linked_content_blob('20160210130454955-23')
    assert ep.can_delete?(pa.user)
    User.with_current_user(pa.user) do
      assert ep.can_delete?
    end

    refute_nil openbis_linked_content_blob('20160210130454955-23', ep)
    refute ep.can_delete?(pa.user)
    User.with_current_user(pa.user) do
      refute ep.can_delete?
    end
  end

  test 'available spaces' do
    endpoint = Factory(:openbis_endpoint)
    spaces = endpoint.available_spaces
    assert_equal 2, spaces.count
  end

  test 'space' do
    endpoint = Factory(:openbis_endpoint)
    space = endpoint.space
    refute_nil space
    assert_equal 'API-SPACE', space.perm_id
  end

  test 'can edit?' do
    pa = Factory(:project_administrator).user
    user = Factory(:person).user
    endpoint = OpenbisEndpoint.create project: pa.person.projects.first, username: 'fred', password: '12345', as_endpoint: 'http://my-openbis.org/openbis', dss_endpoint: 'http://my-openbis.org/openbis', space_perm_id: 'aaa'
    User.with_current_user(pa) do
      with_config_value :openbis_enabled, true do
        assert endpoint.can_edit?
      end

      with_config_value :openbis_enabled, false do
        refute endpoint.can_edit?
      end
    end

    User.with_current_user(user) do
      with_config_value :openbis_enabled, true do
        refute endpoint.can_edit?
      end

      with_config_value :openbis_enabled, false do
        refute endpoint.can_edit?
      end
    end

    User.with_current_user(nil) do
      with_config_value :openbis_enabled, true do
        refute endpoint.can_edit?
      end

      with_config_value :openbis_enabled, false do
        refute endpoint.can_edit?
      end
    end

    with_config_value :openbis_enabled, true do
      assert endpoint.can_edit?(pa)
      refute endpoint.can_edit?(user)
      refute endpoint.can_edit?(nil)

      # cannot edit if another project admin
      pa2 = Factory(:project_administrator).user
      refute endpoint.can_edit?(pa2)
    end
  end

  test 'session token' do
    endpoint = Factory(:openbis_endpoint)

    refute_nil endpoint.session_token
  end

  test 'destroy' do
    pa = Factory(:project_administrator)
    endpoint = Factory(:openbis_endpoint, project: pa.projects.first)
    metadata_store = endpoint.metadata_store
    key = endpoint.space.cache_key(endpoint.space_perm_id)
    assert metadata_store.exist?(key)
    assert_difference('OpenbisEndpoint.count', -1) do
      User.with_current_user(pa.user) do
        endpoint.destroy
      end
    end
    refute metadata_store.exist?(key)
  end

  test 'clear metadata store' do
    endpoint = Factory(:openbis_endpoint)
    key = endpoint.space.cache_key(endpoint.space_perm_id)
    assert endpoint.metadata_store.exist?(key)
    endpoint.clear_metadata_store
    refute endpoint.metadata_store.exist?(key)
  end

  test 'create_refresh_metadata_store_job' do
    endpoint = Factory(:openbis_endpoint)
    Delayed::Job.destroy_all
    refute OpenbisEndpointCacheRefreshJob.new(endpoint).exists?
    assert_difference('Delayed::Job.count', 1) do
      endpoint.create_refresh_metadata_store_job
    end
    assert_no_difference('Delayed::Job.count') do
      endpoint.create_refresh_metadata_store_job
    end
    assert OpenbisEndpointCacheRefreshJob.new(endpoint).exists?
  end

  test 'create job on creation' do
    Delayed::Job.destroy_all
    endpoint = Factory(:openbis_endpoint)
    assert OpenbisEndpointCacheRefreshJob.new(endpoint).exists?
  end

  test 'job destroyed on delete' do
    Delayed::Job.destroy_all
    pa = Factory(:project_administrator)
    endpoint = Factory(:openbis_endpoint, project: pa.projects.first)
    assert_difference('Delayed::Job.count', -1) do
      User.with_current_user(pa.user) do
        endpoint.destroy
      end
    end
    refute OpenbisEndpointCacheRefreshJob.new(endpoint).exists?
  end

  test 'encrypted password' do
    endpoint = OpenbisEndpoint.new project: Factory(:project), username: 'fred', password: 'frog',
                                   web_endpoint: 'http://my-openbis.org/openbis',
                                   as_endpoint: 'http://my-openbis.org/openbis',
                                   dss_endpoint: 'http://my-openbis.org/openbis',
                                   space_perm_id: 'mmmm',
                                   refresh_period_mins: 60
    assert_equal 'frog', endpoint.password
    refute_nil endpoint.encrypted_password
    refute_nil endpoint.encrypted_password_iv

    disable_authorization_checks do
      assert endpoint.save
    end

    endpoint = OpenbisEndpoint.find(endpoint.id)
    assert_equal 'frog', endpoint.password
    refute_nil endpoint.encrypted_password
    refute_nil endpoint.encrypted_password_iv
  end
end
