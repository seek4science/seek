require 'test_helper'

class ProgrammeTest < ActiveSupport::TestCase
  test 'has_member?' do
    programme_administrator = FactoryBot.create(:programme_administrator)
    programme1 = programme_administrator.programmes.first
    programme2 = FactoryBot.create(:programme)

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

    # web_page url must be a valid web url if present
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

    # strips before validation
    p.web_page = '   https://google.com   '
    assert p.valid?
    assert_equal 'https://google.com', p.web_page
  end

  test 'validate title and decription length' do
    long_desc = ('a' * 65536).freeze
    ok_desc = ('a' * 65535).freeze
    long_title = ('a' * 256).freeze
    ok_title = ('a' * 255).freeze
    p = FactoryBot.create(:programme)
    assert p.valid?
    p.title = long_title
    refute p.valid?
    p.title = ok_title
    assert p.valid?
    p.description = long_desc
    refute p.valid?
    p.description = ok_desc
    assert p.valid?
    disable_authorization_checks {p.save!}
  end

  test 'factory' do
    p = FactoryBot.create :programme
    refute_nil p.title
    refute_nil p.uuid
    refute_empty p.projects
  end

  test 'people via projects' do
    person1 = FactoryBot.create :person
    person2 = FactoryBot.create :person
    person3 = FactoryBot.create :person
    assert_equal 1, person1.projects.size
    assert_equal 1, person2.projects.size
    projects = person1.projects | person2.projects
    prog = FactoryBot.create :programme, projects: projects
    assert_equal 2, prog.projects.size
    peeps = prog.people
    assert_equal 2, peeps.size
    assert_includes peeps, person1
    assert_includes peeps, person2
    refute_includes peeps, person3
  end

  test 'institutions via projects' do
    person1 = FactoryBot.create :person
    person2 = FactoryBot.create :person
    person3 = FactoryBot.create :person

    projects = person1.projects | person2.projects
    prog = FactoryBot.create :programme, projects: projects
    assert_equal 2, prog.projects.size
    inst = prog.institutions
    assert_equal 2, inst.size
    assert_includes inst, person1.institutions.first
    assert_includes inst, person2.institutions.first
    refute_includes inst, person3.institutions.first
  end

  test 'can delete' do
    admin = FactoryBot.create(:admin)
    person = FactoryBot.create(:person)

    programme_administrator = FactoryBot.create(:programme_administrator)
    programme = programme_administrator.programmes.first

    refute_empty programme.projects

    refute programme.can_delete?(admin)
    refute programme.can_delete?(programme_administrator)
    refute programme.can_delete?(person)
    refute programme.can_delete?(nil)

    programme.projects = []
    assert_empty programme.projects
    assert programme.can_delete?(admin)
    assert programme.can_delete?(programme_administrator)
    refute programme.can_delete?(person)
    refute programme.can_delete?(nil)
  end


  test 'can be edited by' do
    admin = FactoryBot.create(:admin)
    person = FactoryBot.create(:person)

    programme_administrator = FactoryBot.create(:programme_administrator)
    programme = programme_administrator.programmes.first

    assert programme.can_edit?(admin)
    assert programme.can_edit?(programme_administrator)
    refute programme.can_edit?(person)
    refute programme.can_edit?(nil)
  end

  test 'programme_administrators' do
    person = FactoryBot.create(:person)
    programme = FactoryBot.create(:programme)
    refute person.is_programme_administrator?(programme)
    assert_empty programme.programme_administrators
    person.is_programme_administrator = true, programme
    disable_authorization_checks { person.save! }

    assert person.is_programme_administrator?(programme)
    refute_empty programme.programme_administrators
    assert_equal [person], programme.programme_administrators
  end

  test 'assign adminstrator ids' do
    disable_authorization_checks do
      programme = FactoryBot.create(:programme)
      person = FactoryBot.create(:person)
      person2 = FactoryBot.create(:person)

      programme.update(programme_administrator_ids: [person.id.to_s])
      person.reload
      person2.reload
      programme.reload

      assert person.is_programme_administrator?(programme)
      refute person2.is_programme_administrator?(programme)
      assert_equal [person], programme.programme_administrators

      programme.update(programme_administrator_ids: [person2.id])
      person.reload
      person2.reload
      programme.reload

      refute person.is_programme_administrator?(programme)
      assert person2.is_programme_administrator?(programme)
      assert_equal [person2], programme.programme_administrators

      programme.update(programme_administrator_ids: [person2.id, person.id])
      person.reload
      person2.reload
      programme.reload

      assert person.is_programme_administrator?(programme)
      assert person2.is_programme_administrator?(programme)
      assert_equal [person2, person].sort, programme.programme_administrators.sort
    end
  end

  test 'can create' do
    with_config_value :programme_user_creation_enabled, true do
      User.current_user = nil
      refute Programme.can_create?

      User.current_user = FactoryBot.create(:brand_new_person).user
      refute Programme.can_create?

      User.current_user = FactoryBot.create(:person).user
      assert Programme.can_create?

      User.current_user = FactoryBot.create(:admin).user
      assert Programme.can_create?
    end

    with_config_value :programme_user_creation_enabled, false do
      User.current_user = nil
      refute Programme.can_create?

      User.current_user = FactoryBot.create(:brand_new_person).user
      refute Programme.can_create?

      User.current_user = FactoryBot.create(:person).user
      refute Programme.can_create?

      User.current_user = FactoryBot.create(:admin).user
      assert Programme.can_create?
    end

    with_config_value :programmes_enabled, false do
      User.current_user = nil
      refute Programme.can_create?

      User.current_user = FactoryBot.create(:brand_new_person).user
      refute Programme.can_create?

      User.current_user = FactoryBot.create(:person).user
      refute Programme.can_create?

      User.current_user = FactoryBot.create(:admin).user
      refute Programme.can_create?
    end
  end

  test 'programme activated automatically when created by an admin' do
    User.with_current_user FactoryBot.create(:admin).user do
      prog = Programme.create(title: 'my prog')
      prog.save!
      assert prog.is_activated?
    end
  end

  test 'programme activated automatically when current_user is nil' do
    User.with_current_user nil do
      prog = Programme.create(title: 'my prog')
      prog.save!
      assert prog.is_activated?
    end
  end

  test 'programme not activated automatically when created by a normal user' do
    FactoryBot.create(:admin) # to avoid 1st person being an admin
    User.with_current_user FactoryBot.create(:person).user do
      prog = Programme.create(title: 'my prog')
      prog.save!
      refute prog.is_activated?
    end
  end

  test 'update programme administrators after destroy' do
    User.current_user = FactoryBot.create(:admin)
    pa = FactoryBot.create(:programme_administrator)
    prog = pa.programmes.first
    prog.projects = []
    prog.save!

    assert prog.can_delete?

    assert pa.is_programme_administrator?(prog)
    assert pa.is_programme_administrator_of_any_programme?
    assert pa.has_role?('programme_administrator')

    assert_difference('Programme.count', -1) do
      assert_difference('Role.count', -1) do
        prog.destroy
      end
    end
    pa.reload
    refute pa.is_programme_administrator?(prog)
    refute pa.is_programme_administrator_of_any_programme?
    refute pa.has_role?('programme_administrator')

    # administrator of multiple programmes
    pa = FactoryBot.create(:programme_administrator)
    prog = pa.programmes.first
    prog.projects=[]
    prog.save!
    prog2 = FactoryBot.create(:programme)
    disable_authorization_checks do
      pa.is_programme_administrator = true, prog2
      pa.save!
    end
    pa.reload

    assert pa.is_programme_administrator?(prog)
    assert pa.is_programme_administrator_of_any_programme?
    assert pa.has_role?('programme_administrator')

    assert_difference('Programme.count', -1) do
      assert_difference('Role.count', -1) do
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
    FactoryBot.create(:admin) # to avoid 1st person being an admin
    prog = FactoryBot.create(:programme)
    assert prog.is_activated?
    User.with_current_user FactoryBot.create(:person).user do
      prog.title = 'fish'
      disable_authorization_checks { prog.save! }
      assert prog.is_activated?
    end
  end

  test 'activated scope' do
    activated_prog = FactoryBot.create(:programme)
    not_activated_prog = FactoryBot.create(:programme)
    not_activated_prog.is_activated = false
    disable_authorization_checks { not_activated_prog.save! }

    assert_includes Programme.activated, activated_prog
    refute_includes Programme.activated, not_activated_prog
  end

  test 'activate' do
    prog = FactoryBot.create(:programme)
    prog.is_activated = false
    disable_authorization_checks { prog.save! }

    # no current user
    prog.activate
    refute prog.is_activated?

    # normal user
    User.current_user = FactoryBot.create(:person).user
    prog.activate
    refute prog.is_activated?

    # admin
    User.current_user = FactoryBot.create(:admin).user
    prog.activate
    assert prog.is_activated?

    # reason is wiped
    prog = FactoryBot.create(:programme, activation_rejection_reason: 'it is rubbish')
    prog.is_activated = false
    disable_authorization_checks { prog.save! }
    refute_nil prog.activation_rejection_reason
    prog.activate
    assert prog.is_activated?
    assert_nil prog.activation_rejection_reason
  end

  test 'rejected?' do
    prog = FactoryBot.create(:programme)
    prog.is_activated = false
    disable_authorization_checks { prog.save! }

    refute prog.rejected?

    prog.activation_rejection_reason = 'xxx'
    disable_authorization_checks { prog.save! }
    assert prog.rejected?

    prog.activation_rejection_reason = ''
    disable_authorization_checks { prog.save! }
    assert prog.rejected?

    prog.is_activated = true
    disable_authorization_checks { prog.save! }
    refute prog.rejected?
  end

  test 'rejected scope' do
    Programme.destroy_all
    prog_no_1 = FactoryBot.create(:programme)
    prog_no_1.activation_rejection_reason = ''
    prog_no_1.is_activated = true
    disable_authorization_checks { prog_no_1.save! }

    prog_no_2 = FactoryBot.create(:programme)
    prog_no_2.activation_rejection_reason = nil
    prog_no_2.is_activated = true
    disable_authorization_checks { prog_no_2.save! }

    prog_yes_1 = FactoryBot.create(:programme)
    prog_yes_1.activation_rejection_reason = ''
    prog_yes_1.is_activated = false
    disable_authorization_checks { prog_yes_1.save! }

    prog_yes_2 = FactoryBot.create(:programme)
    prog_yes_2.activation_rejection_reason = 'xxx'
    prog_yes_2.is_activated = false
    disable_authorization_checks { prog_yes_2.save! }

    refute prog_no_1.rejected?
    refute prog_no_2.rejected?
    assert prog_yes_1.rejected?
    assert prog_yes_2.rejected?

    result = Programme.rejected
    assert_kind_of ActiveRecord::Relation, result
    assert_equal [prog_yes_1, prog_yes_2].sort, result.sort
  end

  test 'related items' do
    projects = FactoryBot.create_list(:project, 3)
    programme = FactoryBot.create(:programme, projects: projects)


    projects.each do |project|
      contributor = FactoryBot.create(:person,project:project)
      i = FactoryBot.create(:investigation, projects: [project], contributor:contributor)
      s = FactoryBot.create(:study, investigation: i, contributor:contributor)
      a = FactoryBot.create(:assay, study: s, contributor:contributor)
      project.reload # Can't find investigations of second project if this isn't here!
      assert_includes project.investigations, i
      assert_includes project.studies, s
      assert_includes project.assays, a
      assert_includes programme.investigations, i
      assert_includes programme.studies, s
      assert_includes programme.assays, a
      [:data_files, :models, :sops, :presentations, :events, :publications].each do |type|
        item = FactoryBot.create(type.to_s.singularize.to_sym, projects: [project], contributor:contributor)
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

  test 'funding code' do
    person = FactoryBot.create(:person)
    User.with_current_user person.user do
      prog = FactoryBot.create(:programme)
      prog.funding_codes='fish'
      assert_equal ['fish'],prog.funding_codes.sort
      prog.save!
      prog=Programme.find(prog.id)
      assert_equal ['fish'],prog.funding_codes.sort

      prog.funding_codes='1,2,3'
      assert_equal ['1','2','3'],prog.funding_codes.sort
      prog.save!
      prog=Programme.find(prog.id)
      assert_equal ['1','2','3'],prog.funding_codes.sort

      prog.update_attribute(:funding_codes,'a,b')
      assert_equal ['a','b'],prog.funding_codes.sort
    end
  end

  test 'managed programme' do
    prog1 = FactoryBot.create(:programme)
    prog2 = FactoryBot.create(:programme)
    with_config_value(:managed_programme_id,prog1.id) do
      assert_equal prog1,Programme.site_managed_programme
      assert prog1.site_managed?
      refute prog2.site_managed?
    end
    with_config_value(:managed_programme_id,prog2.id) do
      assert_equal prog2,Programme.site_managed_programme
      refute prog1.site_managed?
      assert prog2.site_managed?
    end
    with_config_value(:managed_programme_id,nil) do
      assert_nil Programme.site_managed_programme
      refute prog1.site_managed?
      refute prog2.site_managed?
    end
  end

  test 'allows_user_projects?' do
    prog = FactoryBot.create(:programme, open_for_projects:true)
    prog2 = FactoryBot.create(:programme, open_for_projects:false)
    with_config_value(:programmes_open_for_projects_enabled, true) do
      assert prog.allows_user_projects?
      refute prog2.allows_user_projects?
    end
    with_config_value(:programmes_open_for_projects_enabled, false) do
      refute prog.allows_user_projects?
      refute prog2.allows_user_projects?
    end
  end

  test 'open for projects scope' do
    prog = FactoryBot.create(:programme, open_for_projects: true)
    prog2 = FactoryBot.create(:programme, open_for_projects: false)
    prog3 = FactoryBot.create(:programme, open_for_projects: true)

    assert_equal [prog, prog3].sort, Programme.open_for_projects.sort
  end

  test 'any_programmes_open_for_projects?' do

    # no programmes
    with_config_value(:programmes_open_for_projects_enabled,true) do
      refute Programme.any_programmes_open_for_projects?
    end

    FactoryBot.create(:programme, open_for_projects: true)
    FactoryBot.create(:programme, open_for_projects: false)

    with_config_value(:programmes_open_for_projects_enabled, true) do
      assert Programme.any_programmes_open_for_projects?
    end
    with_config_value(:programmes_open_for_projects_enabled, false) do
      refute Programme.any_programmes_open_for_projects?
    end

  end

  test 'can_associate_project' do
    person = FactoryBot.create(:person)
    programme_admin = FactoryBot.create(:person)
    open_programme = FactoryBot.create(:programme, open_for_projects: true)
    closed_programme = FactoryBot.create(:programme, open_for_projects: false)

    disable_authorization_checks {
      open_programme.programme_administrators = [programme_admin]
      closed_programme.programme_administrators = [programme_admin]
      open_programme.save!
      closed_programme.save!
    }

    with_config_value(:programmes_open_for_projects_enabled, true) do
      User.with_current_user(person.user) do
        assert open_programme.can_associate_projects?
        refute closed_programme.can_associate_projects?
      end

      User.with_current_user(programme_admin.user) do
        assert open_programme.can_associate_projects?
        assert closed_programme.can_associate_projects?
      end
    end

    with_config_value(:programmes_open_for_projects_enabled, false) do
      User.with_current_user(person.user) do
        refute open_programme.can_associate_projects?
        refute closed_programme.can_associate_projects?
      end

      User.with_current_user(programme_admin.user) do
        assert open_programme.can_associate_projects?
        assert closed_programme.can_associate_projects?
      end
    end
  end

  test 'get related people of empty programmes' do
    person1 = FactoryBot.create(:programme_administrator_not_in_project)
    person2 = FactoryBot.create(:programme_administrator_not_in_project)
    prog = FactoryBot.create(:min_programme, programme_administrators: [person1, person2])

    [person1, person2].each do |p|
      assert_includes prog.related_people, p
    end
  end
end
