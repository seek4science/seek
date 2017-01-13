require 'test_helper'

class OpenbisEndpointTest < ActiveSupport::TestCase

  test 'validation' do
    project=Factory(:project)
    endpoint = OpenbisEndpoint.new project:project, username:'fred', password:'12345',
                                as_endpoint:'http://my-openbis.org/openbis',
                                dss_endpoint:'http://my-openbis.org/openbis',
                                space_perm_id:'mmmm'

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

    endpoint.project=nil
    refute endpoint.valid?
    endpoint.project=Factory(:project)
    assert endpoint.valid?
  end

  test 'link to project' do
    pa=Factory(:project_administrator)
    project=pa.projects.first
    User.with_current_user(pa.user) do
      with_config_value :openbis_enabled,true do
        endpoint = OpenbisEndpoint.create project:project, username:'fred', password:'12345', as_endpoint:'http://my-openbis.org/openbis', dss_endpoint:'http://my-openbis.org/openbis', space_perm_id:'aaa'
        endpoint2 = OpenbisEndpoint.create project:project, username:'fred', password:'12345', as_endpoint:'http://my-openbis.org/openbis', dss_endpoint:'http://my-openbis.org/openbis', space_perm_id:'bbb'
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
    endpoint = Factory(:openbis_endpoint)
    spaces = endpoint.available_spaces
    assert_equal 2,spaces.count
  end

  test 'space' do
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
    endpoint = OpenbisEndpoint.new(project:Factory(:project),
                                   dss_endpoint:'https://openbis-api.fair-dom.org/datastore_server',
                                   as_endpoint:'https://openbis-api.fair-dom.org/openbis/openbis',
                                   username:'apiuser',password:'apiuser',space_perm_id:'API-SPACE')

    refute_nil endpoint.session_token
  end

end