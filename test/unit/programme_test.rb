require 'test_helper'

class ProgrammeTest < ActiveSupport::TestCase

  def setup
    #make sure an admin exists as the first user
    Factory(:admin)
  end

  test 'has_member?' do
    programme_administrator = Factory(:programme_administrator)
    programme1 = programme_administrator.programmes.first
    programme2 = Factory(:programme)

    assert programme1.has_member?(programme_administrator)
    assert programme1.has_member?(programme_administrator.user)

    refute programme2.has_member?(programme_administrator)
    refute programme2.has_member?(programme_administrator.user)

    refute programme2.has_member?(nil)
  end

  test 'uuid' do
    p = Programme.new title: 'fish'
    assert_nil p.attributes['uuid']
    disable_authorization_checks { p.save! }
    refute_nil p.attributes['uuid']
    uuid = p.uuid
    p.title = 'frog'
    disable_authorization_checks { p.save! }
    assert_equal uuid, p.uuid
  end

  test 'validation' do
    p = Programme.new
    refute p.valid?
    p.title = 'frog'
    assert p.valid?
    disable_authorization_checks { p.save! }

    # title must be unique
    p2 = Programme.new title: p.title
    refute p2.valid?
    p2.title = 'sdfsdfsdf'
    assert p2.valid?
    assert p2.valid?

    #web_page url must be a valid web url if present
    p.web_page = nil
    assert p.valid?
    p.web_page = ''
    assert p.valid?
    p.web_page = 'not a url'
    refute p.valid?
    p.web_page = 'ftp://google.com'
    refute p.valid?
    p.web_page = 'http://google.com'
    assert p.valid?
    p.web_page = 'https://google.com'
    assert p.valid?
  end

  test 'factory' do
    p = Factory :programme
    refute_nil p.title
    refute_nil p.uuid
    refute_empty p.projects
  end

  test 'people via projects' do
    person1 = Factory :person
    person2 = Factory :person
    person3 = Factory :person
    assert_equal 1, person1.projects.size
    assert_equal 1, person2.projects.size
    projects = person1.projects | person2.projects
    prog = Factory :programme, projects: projects
    assert_equal 2, prog.projects.size
    peeps = prog.people
    assert_equal 2, peeps.size
    assert_includes peeps, person1
    assert_includes peeps, person2
    refute_includes peeps, person3
  end

  test 'institutions via projects' do
    person1 = Factory :person
    person2 = Factory :person
    person3 = Factory :person

    projects = person1.projects | person2.projects
    prog = Factory :programme, projects: projects
    assert_equal 2, prog.projects.size
    inst = prog.institutions
    assert_equal 2, inst.size
    assert_includes inst, person1.institutions.first
    assert_includes inst, person2.institutions.first
    refute_includes inst, person3.institutions.first
  end

  test "can delete" do
    admin = Factory(:admin)
    person = Factory(:person)

    programme_administrator = Factory(:programme_administrator)
    programme = programme_administrator.programmes.first

    assert programme.can_delete?(admin)
    refute programme.can_delete?(programme_administrator)
    refute programme.can_delete?(person)
    refute programme.can_delete?(nil)
  end

  test 'can be edited by' do
    admin = Factory(:admin)
    person = Factory(:person)

    programme_administrator = Factory(:programme_administrator)
    programme = programme_administrator.programmes.first

    assert programme.can_be_edited_by?(admin)
    assert programme.can_be_edited_by?(programme_administrator)
    refute programme.can_be_edited_by?(person)
    refute programme.can_be_edited_by?(nil)
  end

  test 'disassociate projects on destroy' do
    programme = Factory(:programme)
    project = programme.projects.first
    assert_equal programme.id, project.programme_id
    User.current_user = Factory(:admin).user
    programme.destroy
    project.reload
    assert_nil project.programme_id
  end

  test 'programme_administrators' do
    person = Factory(:person)
    programme = Factory(:programme)
    refute person.is_programme_administrator?(programme)
    assert_empty programme.programme_administrators
    person.is_programme_administrator = true, programme
    disable_authorization_checks { person.save! }

    assert person.is_programme_administrator?(programme)
    refute_empty programme.programme_administrators
    assert_equal [person], programme.programme_administrators
  end

  test 'assign adminstrator ids' do
    programme = Factory(:programme)
    person = Factory(:person)
    person2 = Factory(:person)

    programme.update_attributes(administrator_ids: [person.id.to_s])
    person.reload
    person2.reload
    programme.reload

    assert person.is_programme_administrator?(programme)
    refute person2.is_programme_administrator?(programme)
    assert_equal [person], programme.programme_administrators

    programme.update_attributes(administrator_ids: [person2.id])
    person.reload
    person2.reload
    programme.reload

    refute person.is_programme_administrator?(programme)
    assert person2.is_programme_administrator?(programme)
    assert_equal [person2], programme.programme_administrators

    programme.update_attributes(administrator_ids: [person2.id, person.id])
    person.reload
    person2.reload
    programme.reload

    assert person.is_programme_administrator?(programme)
    assert person2.is_programme_administrator?(programme)
    assert_equal [person2, person].sort, programme.programme_administrators.sort
  end

  test 'can create' do
    with_config_value :programme_user_creation_enabled,true do
      User.current_user = nil
      refute Programme.can_create?

      User.current_user = Factory(:brand_new_person).user
      refute Programme.can_create?

      User.current_user = Factory(:person).user
      assert Programme.can_create?

      User.current_user = Factory(:admin).user
      assert Programme.can_create?
    end

    with_config_value :programme_user_creation_enabled,false do
      User.current_user = nil
      refute Programme.can_create?

      User.current_user = Factory(:brand_new_person).user
      refute Programme.can_create?

      User.current_user = Factory(:person).user
      refute Programme.can_create?

      User.current_user = Factory(:admin).user
      assert Programme.can_create?
    end

    with_config_value :programmes_enabled, false do
      User.current_user = nil
      refute Programme.can_create?

      User.current_user = Factory(:brand_new_person).user
      refute Programme.can_create?

      User.current_user = Factory(:person).user
      refute Programme.can_create?

      User.current_user = Factory(:admin).user
      refute Programme.can_create?
    end
  end

  test 'programme activated automatically when created by an admin' do
    User.with_current_user Factory(:admin).user do
      prog = Programme.create(:title=>"my prog")
      prog.save!
      assert prog.is_activated?
    end
  end

  test 'programme activated automatically when current_user is nil' do
    User.with_current_user nil do
      prog = Programme.create(:title=>"my prog")
      prog.save!
      assert prog.is_activated?
    end
  end

  test 'programme not activated automatically when created by a normal user' do
    Factory(:admin) # to avoid 1st person being an admin
    User.with_current_user Factory(:person).user do
      prog = Programme.create(:title=>"my prog")
      prog.save!
      refute prog.is_activated?
    end
  end

  test 'update programme administrators after destroy' do
    User.current_user=Factory(:admin)
    pa = Factory(:programme_administrator)
    prog = pa.programmes.first

    assert pa.is_programme_administrator?(prog)
    assert pa.is_programme_administrator_of_any_programme?
    assert pa.has_role?('programme_administrator')

    assert_difference('Programme.count', -1) do
      assert_difference('AdminDefinedRoleProgramme.count', -1) do
        prog.destroy
      end
    end
    pa.reload
    refute pa.is_programme_administrator?(prog)
    refute pa.is_programme_administrator_of_any_programme?
    refute pa.has_role?('programme_administrator')

    #administrator of multiple programmes
    pa = Factory(:programme_administrator)
    prog = pa.programmes.first
    prog2 = Factory(:programme)
    disable_authorization_checks do
      pa.is_programme_administrator=true, prog2
      pa.save!
    end
    pa.reload

    assert pa.is_programme_administrator?(prog)
    assert pa.is_programme_administrator_of_any_programme?
    assert pa.has_role?('programme_administrator')

    assert_difference('Programme.count', -1) do
      assert_difference('AdminDefinedRoleProgramme.count', -1) do
        prog.destroy
      end
    end
    pa.reload
    refute pa.is_programme_administrator?(prog)
    assert pa.is_programme_administrator?(prog2)
    assert pa.is_programme_administrator_of_any_programme?
    assert pa.has_role?('programme_administrator')

  end

  test "doesn't change activation flag on later save" do
    Factory(:admin) # to avoid 1st person being an admin
    prog = Factory(:programme)
    assert prog.is_activated?
    User.with_current_user Factory(:person).user do
      prog.title="fish"
      disable_authorization_checks{prog.save!}
      assert prog.is_activated?
    end
  end

  test "activated scope" do
    activated_prog = Factory(:programme)
    not_activated_prog = Factory(:programme)
    not_activated_prog.is_activated=false
    disable_authorization_checks{not_activated_prog.save!}

    assert_includes Programme.activated,activated_prog
    refute_includes Programme.activated,not_activated_prog
  end

  test "activate" do
    prog = Factory(:programme)
    prog.is_activated=false
    disable_authorization_checks{prog.save!}

    #no current user
    prog.activate
    refute prog.is_activated?

    #normal user
    User.current_user=Factory(:person).user
    prog.activate
    refute prog.is_activated?

    #admin
    User.current_user=Factory(:admin).user
    prog.activate
    assert prog.is_activated?

    #reason is wiped
    prog = Factory(:programme,activation_rejection_reason:'it is rubbish')
    prog.is_activated=false
    disable_authorization_checks{prog.save!}
    refute_nil prog.activation_rejection_reason
    prog.activate
    assert prog.is_activated?
    assert_nil prog.activation_rejection_reason
  end

  test "rejected?" do
    prog = Factory(:programme)
    prog.is_activated=false
    disable_authorization_checks{prog.save!}

    refute prog.rejected?

    prog.activation_rejection_reason='xxx'
    disable_authorization_checks{prog.save!}
    assert prog.rejected?

    prog.activation_rejection_reason=''
    disable_authorization_checks{prog.save!}
    assert prog.rejected?

    prog.is_activated=true
    disable_authorization_checks{prog.save!}
    refute prog.rejected?
  end

  test "rejected scope" do
    Programme.destroy_all
    prog_no_1 = Factory(:programme)
    prog_no_1.activation_rejection_reason=''
    prog_no_1.is_activated=true
    disable_authorization_checks{prog_no_1.save!}

    prog_no_2 = Factory(:programme)
    prog_no_2.activation_rejection_reason=nil
    prog_no_2.is_activated=true
    disable_authorization_checks{prog_no_2.save!}

    prog_yes_1 = Factory(:programme)
    prog_yes_1.activation_rejection_reason=''
    prog_yes_1.is_activated=false
    disable_authorization_checks{prog_yes_1.save!}

    prog_yes_2 = Factory(:programme)
    prog_yes_2.activation_rejection_reason='xxx'
    prog_yes_2.is_activated=false
    disable_authorization_checks{prog_yes_2.save!}

    refute prog_no_1.rejected?
    refute prog_no_2.rejected?
    assert prog_yes_1.rejected?
    assert prog_yes_2.rejected?

    result = Programme.rejected
    assert_instance_of ActiveRecord::Relation, result
    assert_equal [prog_yes_1,prog_yes_2].sort,result.sort

  end

  test 'related items' do
    projects = FactoryGirl.create_list(:project, 3)
    programme = Factory(:programme, projects: projects)

    projects.each do |project|
      i = Factory(:investigation, projects: [project])
      s = Factory(:study, investigation: i)
      a = Factory(:assay, study: s)
      project.reload # Can't find investigations of second project if this isn't here!
      assert_includes project.investigations, i
      assert_includes project.studies, s
      assert_includes project.assays, a
      assert_includes programme.investigations, i
      assert_includes programme.studies, s
      assert_includes programme.assays, a
      [:data_files, :models, :sops, :presentations, :events, :publications].each do |type|
        item = Factory(type.to_s.singularize.to_sym, projects: [project])
        assert_includes project.send(type), item, "Project related #{type} didn't include item"
        assert_includes programme.send(type), item, "Programme related #{type} didn't include item"
      end
    end

    assert_equal 3, programme.projects.count
    assert_equal 3, programme.investigations.count
    assert_equal 3, programme.studies.count
    assert_equal 3, programme.assays.count
    [:data_files, :models, :sops, :presentations, :events, :publications].each do |type|
      assert_equal 3, programme.send(type).count
    end
  end

end
