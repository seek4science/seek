require 'test_helper'

class OpenbisSpaceTest < ActiveSupport::TestCase


  test 'validation' do
    project=Factory(:project)
    space = OpenbisSpace.new project:project,username:'fred',password:'12345',url:'http://my-openbis.org/openbis',space_name:'mmmm'

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

    space.url=nil
    refute space.valid?
    space.url='fish'
    refute space.valid?
    space.url='http://my-openbis.org/openbis'
    assert space.valid?

    space.project=nil
    refute space.valid?
    space.project=Factory(:project)
    assert space.valid?
  end

  test 'link to project' do
    project=Factory(:project)
    space = OpenbisSpace.create project:project,username:'fred',password:'12345',url:'http://my-openbis.org/openbis',space_name:'aaa'
    space2 = OpenbisSpace.create project:project,username:'fred',password:'12345',url:'http://my-openbis.org/openbis',space_name:'bbb'
    project.reload
    assert_equal [space,space2].sort,project.openbis_spaces
  end

end