require 'test_helper'

class OpenbisSpaceTest < ActiveSupport::TestCase

  test 'validation' do
    project=Factory(:project)
    space = OpenbisSpace.new project:project,username:'fred',password:'12345',
                             as_endpoint:'http://my-openbis.org/openbis',
                             dss_endpoint:'http://my-openbis.org/openbis',
                             space_name:'mmmm'

    assert space.valid?
    space.username=nil
    refute space.valid?
    space.username='fred'
    assert space.valid?

    space.password=nil
    refute space.valid?
    space.password='12345'
    assert space.valid?

    space.space_name=nil
    refute space.valid?
    space.space_name='mmmmm'
    assert space.valid?

    space.as_endpoint=nil
    refute space.valid?
    space.as_endpoint='fish'
    refute space.valid?
    space.as_endpoint='http://my-openbis.org/openbis'
    assert space.valid?

    space.dss_endpoint=nil
    refute space.valid?
    space.dss_endpoint='fish'
    refute space.valid?
    space.dss_endpoint='http://my-openbis.org/openbis'
    assert space.valid?

    space.project=nil
    refute space.valid?
    space.project=Factory(:project)
    assert space.valid?
  end

  test 'link to project' do
    pa=Factory(:project_administrator)
    project=pa.projects.first
    User.with_current_user(pa.user) do
      with_config_value :openbis_enabled,true do
        space = OpenbisSpace.create project:project,username:'fred',password:'12345',as_endpoint:'http://my-openbis.org/openbis',dss_endpoint:'http://my-openbis.org/openbis',space_name:'aaa'
        space2 = OpenbisSpace.create project:project,username:'fred',password:'12345',as_endpoint:'http://my-openbis.org/openbis',dss_endpoint:'http://my-openbis.org/openbis',space_name:'bbb'
        space.save!
        space2.save!
        project.reload
        assert_equal [space,space2].sort,project.openbis_spaces.sort
      end
    end
  end

  test 'can_create' do
    User.with_current_user(Factory(:project_administrator).user) do
      with_config_value :openbis_enabled,true do
        assert OpenbisSpace.can_create?
      end

      with_config_value :openbis_enabled,false do
        refute OpenbisSpace.can_create?
      end
    end

    User.with_current_user(Factory(:person).user) do
      with_config_value :openbis_enabled,true do
        refute OpenbisSpace.can_create?
      end

      with_config_value :openbis_enabled,false do
        refute OpenbisSpace.can_create?
      end
    end

    User.with_current_user(nil) do
      with_config_value :openbis_enabled,true do
        refute OpenbisSpace.can_create?
      end

      with_config_value :openbis_enabled,false do
        refute OpenbisSpace.can_create?
      end
    end
  end

  test 'can edit?' do
    pa=Factory(:project_administrator).user
    user=Factory(:person).user
    space = OpenbisSpace.create project:pa.person.projects.first,username:'fred',password:'12345',as_endpoint:'http://my-openbis.org/openbis',dss_endpoint:'http://my-openbis.org/openbis',space_name:'aaa'
    User.with_current_user(pa) do
      with_config_value :openbis_enabled,true do
        assert space.can_edit?
      end

      with_config_value :openbis_enabled,false do
        refute space.can_edit?
      end
    end

    User.with_current_user(user) do
      with_config_value :openbis_enabled,true do
        refute space.can_edit?
      end

      with_config_value :openbis_enabled,false do
        refute space.can_edit?
      end
    end

    User.with_current_user(nil) do
      with_config_value :openbis_enabled,true do
        refute space.can_edit?
      end

      with_config_value :openbis_enabled,false do
        refute space.can_edit?
      end
    end

    with_config_value :openbis_enabled,true do
      assert space.can_edit?(pa)
      refute space.can_edit?(user)
      refute space.can_edit?(nil)

      #cannot edit if another project admin
      pa2=Factory(:project_administrator).user
      refute space.can_edit?(pa2)

    end
  end

end