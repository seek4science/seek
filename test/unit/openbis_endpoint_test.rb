require 'test_helper'
require 'openbis_test_helper'

class OpenbisEndpointTest < ActiveSupport::TestCase

  test 'validation' do
    project=Factory(:project)
    endpoint = OpenbisEndpoint.new project: project, username: 'fred', password: '12345',
                                   web_endpoint: 'http://my-openbis.org/openbis',
                                   as_endpoint: 'http://my-openbis.org/openbis',
                                   dss_endpoint: 'http://my-openbis.org/openbis',
                                   space_perm_id: 'mmmm'

    assert endpoint.valid?
    endpoint.username=nil
    refute endpoint.valid?
    endpoint.username='fred'
    assert endpoint.valid?

    endpoint.password=nil
    refute endpoint.valid?
    endpoint.password='12345'
    assert endpoint.valid?

    endpoint.space_perm_id=nil
    refute endpoint.valid?
    endpoint.space_perm_id='mmmmm'
    assert endpoint.valid?

    endpoint.as_endpoint=nil
    refute endpoint.valid?
    endpoint.as_endpoint='fish'
    refute endpoint.valid?
    endpoint.as_endpoint='http://my-openbis.org/openbis'
    assert endpoint.valid?

    endpoint.dss_endpoint=nil
    refute endpoint.valid?
    endpoint.dss_endpoint='fish'
    refute endpoint.valid?
    endpoint.dss_endpoint='http://my-openbis.org/openbis'
    assert endpoint.valid?

    endpoint.web_endpoint=nil
    refute endpoint.valid?
    endpoint.web_endpoint='fish'
    refute endpoint.valid?
    endpoint.web_endpoint='http://my-openbis.org/openbis'
    assert endpoint.valid?

    endpoint.project=nil
    refute endpoint.valid?
    endpoint.project=Factory(:project)
    assert endpoint.valid?
  end

  test 'validates uniqueness' do
    endpoint = Factory(:openbis_endpoint)
    endpoint2 = Factory.build(:openbis_endpoint)
    assert endpoint.valid? #different project
    endpoint2 = Factory.build(:openbis_endpoint,project:endpoint.project)
    refute endpoint2.valid?
    endpoint2.as_endpoint='http://fish.com'
    assert endpoint2.valid?
    endpoint2.as_endpoint=endpoint.as_endpoint
    refute endpoint2.valid?
    endpoint2.dss_endpoint='http://fish.com'
    assert endpoint2.valid?
  end

  test 'link to project' do
    pa=Factory(:project_administrator)
    project=pa.projects.first
    User.with_current_user(pa.user) do
      with_config_value :openbis_enabled,true do
        endpoint = OpenbisEndpoint.create project:project, username:'fred', password:'12345', as_endpoint:'http://my-openbis.org/openbis', dss_endpoint:'http://my-openbis.org/openbis',web_endpoint:'http://my-openbis.org/openbis', space_perm_id:'aaa'
        endpoint2 = OpenbisEndpoint.create project:project, username:'fred', password:'12345', as_endpoint:'http://my-openbis.org/openbis', dss_endpoint:'http://my-openbis.org/openbis',web_endpoint:'http://my-openbis.org/openbis', space_perm_id:'bbb'
        endpoint.save!
        endpoint2.save!
        project.reload
        assert_equal [endpoint,endpoint2].sort,project.openbis_endpoints.sort
      end
    end
  end

  test 'can_create' do
    User.with_current_user(Factory(:project_administrator).user) do
      with_config_value :openbis_enabled,true do
        assert OpenbisEndpoint.can_create?
      end

      with_config_value :openbis_enabled,false do
        refute OpenbisEndpoint.can_create?
      end
    end

    User.with_current_user(Factory(:person).user) do
      with_config_value :openbis_enabled,true do
        refute OpenbisEndpoint.can_create?
      end

      with_config_value :openbis_enabled,false do
        refute OpenbisEndpoint.can_create?
      end
    end

    User.with_current_user(nil) do
      with_config_value :openbis_enabled,true do
        refute OpenbisEndpoint.can_create?
      end

      with_config_value :openbis_enabled,false do
        refute OpenbisEndpoint.can_create?
      end
    end
  end

  test 'available spaces' do
    mock_openbis_calls
    endpoint = Factory(:openbis_endpoint)
    spaces = endpoint.available_spaces
    assert_equal 2,spaces.count
  end

  test 'space' do
    mock_openbis_calls
    endpoint = Factory(:openbis_endpoint)
    space = endpoint.space
    refute_nil space
    assert_equal 'API-SPACE',space.perm_id
  end


  test 'can edit?' do
    pa=Factory(:project_administrator).user
    user=Factory(:person).user
    endpoint = OpenbisEndpoint.create project:pa.person.projects.first, username:'fred', password:'12345', as_endpoint:'http://my-openbis.org/openbis', dss_endpoint:'http://my-openbis.org/openbis', space_perm_id:'aaa'
    User.with_current_user(pa) do
      with_config_value :openbis_enabled,true do
        assert endpoint.can_edit?
      end

      with_config_value :openbis_enabled,false do
        refute endpoint.can_edit?
      end
    end

    User.with_current_user(user) do
      with_config_value :openbis_enabled,true do
        refute endpoint.can_edit?
      end

      with_config_value :openbis_enabled,false do
        refute endpoint.can_edit?
      end
    end

    User.with_current_user(nil) do
      with_config_value :openbis_enabled,true do
        refute endpoint.can_edit?
      end

      with_config_value :openbis_enabled,false do
        refute endpoint.can_edit?
      end
    end

    with_config_value :openbis_enabled,true do
      assert endpoint.can_edit?(pa)
      refute endpoint.can_edit?(user)
      refute endpoint.can_edit?(nil)

      #cannot edit if another project admin
      pa2=Factory(:project_administrator).user
      refute endpoint.can_edit?(pa2)

    end
  end

  test 'session token' do
    mock_openbis_calls
    endpoint = Factory(:openbis_endpoint)

    refute_nil endpoint.session_token
  end

  test 'cache key' do
    endpoint = OpenbisEndpoint.new username:'fred', password:'12345', as_endpoint:'http://my-openbis.org/openbis', dss_endpoint:'http://my-openbis.org/openbis', space_perm_id:'aaa'
    assert_equal 'openbis_endpoints/new-ddf17b57f57098ff63383825125f00089a1e1c1cc4de18b27e30e3b9642854a9',endpoint.cache_key
    endpoint.space_perm_id='bbb'
    assert_equal 'openbis_endpoints/new-867be42425f47d36cc6b91926853a714251da75cea9c7517046e610d2f0201ca',endpoint.cache_key

    endpoint = Factory(:openbis_endpoint)
    assert_equal "openbis_endpoints/#{endpoint.id}-#{endpoint.updated_at.utc.to_s(:number)}",endpoint.cache_key
  end

  test 'clear cache' do
    mock_openbis_calls
    endpoint = Factory(:openbis_endpoint)
    key = endpoint.space.cache_key(endpoint.space_perm_id)
    assert Rails.cache.exist?(key)
    endpoint.clear_cache
    refute Rails.cache.exist?(key)
  end

end