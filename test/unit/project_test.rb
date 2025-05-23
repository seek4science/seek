require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  fixtures :projects, :institutions, :work_groups, :group_memberships, :people, :users, :assets, :organisms


  test 'workgroups destroyed with project' do
    project = FactoryBot.create(:person).projects.first
    person = FactoryBot.create(:person)
    disable_authorization_checks do
      person.add_to_project_and_institution(project, project.institutions.first)
      person.save!

      wg = project.work_groups.last
      assert_equal 2, wg.people.count

      person2 = FactoryBot.create(:person)
      person2.add_to_project_and_institution(project, FactoryBot.create(:institution))
      person2.save!

      assert_equal 2, project.work_groups.count
      assert_equal 3, project.people.count
      assert_equal 3, project.group_memberships.count

      assert_difference('WorkGroup.count', -2) do
        assert_difference('GroupMembership.count', -3) do
          assert_no_difference('Person.count') do
            assert_difference('Project.count', -1) do
              project.destroy
            end
          end
        end
      end

      assert_nil WorkGroup.find_by_id(wg.id)
      assert_nil Project.find_by_id(project.id)
      refute_nil Person.find_by_id(person.id)
      refute_nil Person.find_by_id(person2.id)
    end
  end

  test 'validate title and decription length' do
    long_desc = ('a' * 65536).freeze
    ok_desc = ('a' * 65535).freeze
    long_title = ('a' * 256).freeze
    ok_title = ('a' * 255).freeze
    p = FactoryBot.create(:project)
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

  test 'validate start and end date' do
    # if start and end date are defined, then the end date must be later
    p = FactoryBot.create(:project,start_date:nil, end_date:nil)
    assert p.valid?

    #just an end date
    p.end_date = DateTime.now
    assert p.valid?

    #start date in the future
    p.start_date = DateTime.now + 1.day
    refute p.valid?

    #start date in the past
    p.start_date = 1.day.ago
    assert p.valid?

    # no end date
    p.start_date = DateTime.now + 1.day
    p.end_date = nil
    assert p.valid?

    # future start and end dates are fine as long as end is later
    p.start_date = DateTime.now + 1.day
    p.end_date = DateTime.now + 2.day
    assert p.valid?
  end

  test 'to_rdf' do
    object = FactoryBot.create :project, web_page: 'http://www.sysmo-db.org',
                               organisms: [FactoryBot.create(:organism), FactoryBot.create(:organism)]
    person = FactoryBot.create(:person,project:object)
    df = FactoryBot.create :data_file, projects: [object], contributor:person
    FactoryBot.create :data_file, projects: [object], contributor:person
    FactoryBot.create :model, projects: [object], contributor:person
    FactoryBot.create :sop, projects: [object], contributor:person
    presentation = FactoryBot.create :presentation, projects: [object], contributor:person
    doc = FactoryBot.create :document, projects: [object], contributor:person
    i = FactoryBot.create :investigation, projects: [object], contributor:person
    s = FactoryBot.create :study, investigation: i, contributor:person
    FactoryBot.create :assay, study: s, contributor:person


    object.reload
    refute object.people.empty?
    rdf = object.to_rdf
    graph = RDF::Graph.new do |graph|
      RDF::Reader.for(:ttl).new(rdf) {|reader| graph << reader}
    end

    assert graph.statements.count > 1
    assert_equal RDF::URI.new("http://localhost:3000/projects/#{object.id}"), graph.statements.first.subject

    #check includes the data file due to bug OPSK-1919
    refute_nil graph.statements.detect{|s| s.object == RDF::URI.new("http://localhost:3000/data_files/#{df.id}") && s.predicate == RDF::URI("http://jermontology.org/ontology/JERMOntology#hasItem")}

    #document and presentation shouldn't be present (see OPSK-1920)
    assert_nil graph.statements.detect{|s| s.object == RDF::URI.new("http://localhost:3000/presentations/#{presentation.id}") && s.predicate == RDF::URI("http://jermontology.org/ontology/JERMOntology#hasItem")}
    assert_nil graph.statements.detect{|s| s.object == RDF::URI.new("http://localhost:3000/documents/#{doc.id}") && s.predicate == RDF::URI("http://jermontology.org/ontology/JERMOntology#hasItem")}

  end



  test 'rdf for web_page - existing or blank or nil' do
    object = FactoryBot.create :project, web_page: 'http://google.com'

    homepage_predicate = RDF::URI.new 'http://xmlns.com/foaf/0.1/homepage'
    found = false
    graph = RDF::Graph.new do |graph|
      RDF::Reader.for(:ttl).new(object.to_rdf) {|reader| graph << reader}
    end

    graph.each_statement do |statement|
      next unless statement.predicate == homepage_predicate
      found = true
      assert statement.valid?, 'statement is not valid'
      assert_equal RDF::Literal::AnyURI.new('http://google.com'), statement.object
    end

    assert found, "Didn't find homepage predicate"

    object.web_page = ''
    found = false
    graph = RDF::Graph.new do |graph|
      RDF::Reader.for(:ttl).new(object.to_rdf) {|reader| graph << reader}
    end

    found = graph.statements.select do |statement|
      statement.predicate == homepage_predicate
    end.any?

    refute found, 'The homepage statement should have been skipped'

    object.web_page = nil
    found = false
    graph = RDF::Graph.new do |graph|
      RDF::Reader.for(:ttl).new(object.to_rdf) {|reader| graph << reader}
    end

    found = graph.statements.select do |statement|
      statement.predicate == homepage_predicate
    end.any?

    refute found, 'The homepage statement should have been skipped'
  end

  def test_avatar_key
    p = projects(:sysmo_project)
    assert_nil p.avatar_key
    assert p.defines_own_avatar?
  end

  test 'has_member' do
    person = FactoryBot.create :person
    project = person.projects.first
    other_person = FactoryBot.create :person
    assert project.has_member?(person)
    assert project.has_member?(person.user)
    assert !project.has_member?(other_person)
    assert !project.has_member?(other_person.user)
    assert !project.has_member?(nil)
  end

  def test_title_trimmed
    p = Project.new(title: ' test project')
    disable_authorization_checks { p.save! }
    assert_equal('test project', p.title)
  end

  test 'can set site credentials' do
    p = projects(:sysmo_project)
    p.site_username = 'fred'
    p.site_password = '12345'
    disable_authorization_checks { p.save! }

    username_setting = p.settings.where(var: 'site_username').first
    password_setting = p.settings.where(var: 'site_password').first

    assert username_setting.encrypted?
    assert_equal 'fred', username_setting.value
    assert_nil username_setting[:value]
    refute_equal 'fred', username_setting[:encrypted_value]

    assert password_setting.encrypted?
    assert_equal '12345', password_setting.value
    assert_nil password_setting[:value]
    refute_equal '12345', password_setting[:encrypted_value]

    assert_equal 'fred', p.site_username
    assert_equal '12345', p.site_password
  end

  def test_publications_association
    project = FactoryBot.create(:project)
    onePubl = FactoryBot.create(:publication, projects: [project])
    twoPubl = FactoryBot.create(:publication, projects: [project])
    threePubl = FactoryBot.create(:publication, projects: [project])
    FactoryBot.create(:publication, projects: [project])
    FactoryBot.create(:publication, projects: [project])

    assert_equal 5, project.publications.count

    assert project.publications.include?(onePubl)
    assert project.publications.include?(twoPubl)
    assert project.publications.include?(threePubl)
  end



  def test_can_be_edited_by
    u = FactoryBot.create(:project_administrator).user
    p = u.person.projects.first
    assert p.can_edit?(u), 'Project should be editable by user :project_administrator'

    p = FactoryBot.create(:project)
    assert !p.can_edit?(u), 'other project should not be editable by project administrator, since it is not a project he administers'
  end

  test 'can be edited by programme adminstrator' do
    pa = FactoryBot.create(:programme_administrator)
    project = pa.programmes.first.projects.first
    other_project = FactoryBot.create(:project)

    assert project.can_edit?(pa.user)
    refute other_project.can_edit?(pa.user)
  end

  test 'can be edited by project member' do
    admin = FactoryBot.create(:admin)
    person = FactoryBot.create(:person)
    project = person.projects.first
    refute_nil project
    another_person = FactoryBot.create(:person)

    assert project.can_edit?(person.user)
    refute project.can_edit?(another_person.user)

    User.with_current_user person.user do
      assert project.can_edit?
    end

    User.with_current_user another_person.user do
      refute project.can_edit?
    end
  end

  test 'can be administered by' do
    admin = FactoryBot.create(:admin)
    project_administrator = FactoryBot.create(:project_administrator)
    normal = FactoryBot.create(:person)
    another_proj = FactoryBot.create(:project)

    assert project_administrator.projects.first.can_manage?(project_administrator.user)
    assert !normal.projects.first.can_manage?(normal.user)

    assert !another_proj.can_manage?(normal.user)
    assert !another_proj.can_manage?(project_administrator.user)
    assert another_proj.can_manage?(admin.user)
  end

  test 'can manage' do
    admin = FactoryBot.create(:admin)
    project_administrator = FactoryBot.create(:project_administrator)
    normal = FactoryBot.create(:person)
    another_proj = FactoryBot.create(:project)

    assert project_administrator.projects.first.can_manage?(project_administrator.user)
    refute normal.projects.first.can_manage?(normal.user)

    refute another_proj.can_manage?(nil)
    refute another_proj.can_manage?(normal.user)
    refute another_proj.can_manage?(project_administrator.user)
    assert another_proj.can_manage?(admin.user)
  end

  test 'can be administered by programme administrator' do
    # programme administrator should be able to administer projects belonging to programme
    pa = FactoryBot.create(:programme_administrator)
    project = pa.programmes.first.projects.first
    other_project = FactoryBot.create(:project)

    assert project.can_manage?(pa.user)
    refute other_project.can_manage?(pa.user)
  end

  test 'update with attributes for project_administrator_ids ids' do
    disable_authorization_checks do
      person = FactoryBot.create(:person)
      another_person = FactoryBot.create(:person)

      project = person.projects.first
      refute_nil project

      another_person.add_to_project_and_institution(project, FactoryBot.create(:institution))
      another_person.save!

      refute_includes project.project_administrators, person
      refute_includes project.project_administrators, another_person

      assert project.update(project_administrator_ids: [person.id.to_s])

      assert_includes project.project_administrators, person
      refute_includes project.project_administrators, another_person

      assert project.update(project_administrator_ids: [another_person.id.to_s])

      refute_includes project.project_administrators, person
      assert_includes project.project_administrators, another_person

      # cannot change to a person from another project
      person_in_other_project = FactoryBot.create(:person)
      assert_raise(ActiveRecord::RecordInvalid) do
        project.update(project_administrator_ids: [person_in_other_project.id.to_s])
      end
      refute_includes project.project_administrators, person_in_other_project
    end
  end

  test 'update with attributes for gatekeeper ids' do
    disable_authorization_checks do
      person = FactoryBot.create(:person)
      another_person = FactoryBot.create(:person)

      project = person.projects.first
      refute_nil project

      another_person.add_to_project_and_institution(project, FactoryBot.create(:institution))
      another_person.save!

      refute_includes project.asset_gatekeepers, person
      refute_includes project.asset_gatekeepers, another_person

      assert project.update(asset_gatekeeper_ids: [person.id.to_s])

      assert_includes project.asset_gatekeepers, person
      refute_includes project.asset_gatekeepers, another_person

      assert project.update(asset_gatekeeper_ids: [another_person.id.to_s])

      refute_includes project.asset_gatekeepers, person
      assert_includes project.asset_gatekeepers, another_person

      # 2 at once
      assert project.update(asset_gatekeeper_ids: [person.id.to_s, another_person.id.to_s])
      assert_includes project.asset_gatekeepers, person
      assert_includes project.asset_gatekeepers, another_person

      # cannot change to a person from another project
      person_in_other_project = FactoryBot.create(:person)
      assert_raise(ActiveRecord::RecordInvalid) do
        project.update(asset_gatekeeper_ids: [person_in_other_project.id.to_s])
      end
      refute_includes project.asset_gatekeepers, person_in_other_project
    end
  end

  test 'update with attributes for pal ids' do
    disable_authorization_checks do
      person = FactoryBot.create(:person)
      another_person = FactoryBot.create(:person)

      project = person.projects.first
      refute_nil project

      another_person.add_to_project_and_institution(project, FactoryBot.create(:institution))
      another_person.save!

      refute_includes project.pals, person
      refute_includes project.pals, another_person

      assert project.update(pal_ids: [person.id.to_s])

      assert_includes project.pals, person
      refute_includes project.pals, another_person

      assert project.update(pal_ids: [another_person.id.to_s])

      refute_includes project.pals, person
      assert_includes project.pals, another_person

      # cannot change to a person from another project
      person_in_other_project = FactoryBot.create(:person)
      assert_raise(ActiveRecord::RecordInvalid) do
        project.update(pal_ids: [person_in_other_project.id.to_s])
      end
      refute_includes project.pals, person_in_other_project
    end
  end

  test 'update with attributes for asset housekeeper ids' do
    disable_authorization_checks do
      person = FactoryBot.create(:person)
      another_person = FactoryBot.create(:person)

      project = person.projects.first
      refute_nil project

      another_person.add_to_project_and_institution(project, FactoryBot.create(:institution))
      another_person.save!

      refute_includes project.asset_housekeepers, person
      refute_includes project.asset_housekeepers, another_person

      assert project.update(asset_housekeeper_ids: [person.id.to_s])

      assert_includes project.asset_housekeepers, person
      refute_includes project.asset_housekeepers, another_person

      assert project.update(asset_housekeeper_ids: [another_person.id.to_s])

      refute_includes project.asset_housekeepers, person
      assert_includes project.asset_housekeepers, another_person

      # 2 at once
      assert project.update(asset_housekeeper_ids: [person.id.to_s, another_person.id.to_s])
      assert_includes project.asset_housekeepers, person
      assert_includes project.asset_housekeepers, another_person

      # cannot change to a person from another project
      person_in_other_project = FactoryBot.create(:person)
      assert_raise(ActiveRecord::RecordInvalid) do
        project.update(asset_housekeeper_ids: [person_in_other_project.id.to_s])
      end
      refute_includes project.asset_housekeepers, person_in_other_project
    end
  end

  def test_update_first_letter
    p = Project.new(title: 'test project')
    disable_authorization_checks { p.save! }
    assert_equal 'T', p.first_letter
  end

  test 'validation' do
    p = projects(:one)

    p.web_page = nil
    assert p.valid?

    p.web_page = ''
    assert p.valid?

    p.web_page = 'sdfsdf'
    assert !p.valid?

    p.web_page = 'http://google.com'
    assert p.valid?

    p.web_page = 'https://google.com'
    assert p.valid?

    # gets stripped before validation
    p.web_page = '   https://google.com   '
    assert p.valid?
    assert_equal 'https://google.com', p.web_page

    p.web_page = 'http://google.com/fred'
    assert p.valid?

    p.web_page = 'http://google.com/fred?param=bob'
    assert p.valid?

    p.web_page = 'http://www.mygrid.org.uk/dev/issues/secure/IssueNavigator.jspa?reset=true&mode=hide&sorter/order=DESC&sorter/field=priority&resolution=-1&pid=10051&fixfor=10110'
    assert p.valid?

    p.wiki_page = nil
    assert p.valid?

    p.wiki_page = ''
    assert p.valid?

    p.wiki_page = 'sdfsdf'
    assert !p.valid?

    p.wiki_page = 'http://google.com'
    assert p.valid?

    p.wiki_page = 'https://google.com'
    assert p.valid?

    # gets stripped before validation
    p.wiki_page = '   https://google.com   '
    assert p.valid?
    assert_equal 'https://google.com', p.wiki_page

    p.wiki_page = 'http://google.com/fred'
    assert p.valid?

    p.wiki_page = 'http://google.com/fred?param=bob'
    assert p.valid?

    p.wiki_page = 'http://www.mygrid.org.uk/dev/issues/secure/IssueNavigator.jspa?reset=true&mode=hide&sorter/order=DESC&sorter/field=priority&resolution=-1&pid=10051&fixfor=10110'
    assert p.valid?

    p.title = nil
    assert !p.valid?

    p.title = ''
    assert !p.valid?

    p.title = 'fred'
    assert p.valid?
  end

  test 'test uuid generated' do
    p = projects(:one)
    assert_nil p.attributes['uuid']
    p.save
    assert_not_nil p.attributes['uuid']
  end

  test "uuid doesn't change" do
    x = projects(:one)
    x.save
    uuid = x.attributes['uuid']
    x.save
    assert_equal x.uuid, uuid
  end

  test 'project_admin_can_delete' do
    u = FactoryBot.create(:project_administrator).user
    p = u.person.projects.first
    assert p.can_delete?(u)
  end

  test 'can_delete?' do
    project = FactoryBot.create(:project)

    # none-admin can not delete
    user = FactoryBot.create(:user)
    assert !user.is_admin?
    assert project.work_groups.collect(&:people).flatten.empty?
    assert !project.can_delete?(user)

    # can delete if workgroups contain people
    user = FactoryBot.create(:admin).user
    assert user.is_admin?
    project = FactoryBot.create(:project)
    work_group = FactoryBot.create(:work_group, project: project)
    a_person = FactoryBot.create(:person, group_memberships: [FactoryBot.create(:group_membership, work_group: work_group)])
    refute project.work_groups.collect(&:people).flatten.empty?
    assert project.can_delete?(user)

    # can delete if admin and workgroups are empty
    work_group.group_memberships.delete_all
    assert project.work_groups.reload.collect(&:people).flatten.empty?
    assert user.is_admin?
    assert project.can_delete?(user)

    # cannot delete if there are assets, even if no people
    user = FactoryBot.create(:admin).user
    project = FactoryBot.create(:project)
    assert_empty project.people
    assert project.can_delete?(user)
    FactoryBot.create(:investigation, projects:[project])
    project.work_groups.clear # FactoryBot - with_project_contributor automatically adds the contributor to the project
    project.reload
    assert_empty project.people
    refute_empty project.investigations
    refute project.can_delete?(user)

    project = FactoryBot.create(:project)
    FactoryBot.create(:study, investigation: FactoryBot.create(:investigation, projects:[project]))
    project.work_groups.clear
    project.reload
    refute_empty project.studies
    refute project.can_delete?(user)

    project = FactoryBot.create(:project)
    FactoryBot.create(:assay, study: FactoryBot.create(:study, investigation: FactoryBot.create(:investigation, projects:[project])))
    project.work_groups.clear
    project.reload
    refute_empty project.assays
    refute project.can_delete?(user)

    project = FactoryBot.create(:project)
    FactoryBot.create(:sop, projects:[project])
    project.work_groups.clear
    project.reload
    refute_empty project.sops
    refute project.can_delete?(user)

    project = FactoryBot.create(:project)
    FactoryBot.create(:workflow, projects:[project])
    project.work_groups.clear
    project.reload
    refute_empty project.workflows
    refute project.can_delete?(user)

    project = FactoryBot.create(:project)
    FactoryBot.create(:workflow, projects:[project])
    project.work_groups.clear
    project.reload
    refute_empty project.workflows
    refute project.can_delete?(user)

    project = FactoryBot.create(:project)
    FactoryBot.create(:sample, projects:[project])
    project.work_groups.clear
    project.reload
    refute_empty project.samples
    refute project.can_delete?(user)

    project = FactoryBot.create(:project)
    FactoryBot.create(:simple_sample_type, projects:[project])
    project.work_groups.clear
    project.reload
    refute_empty project.sample_types
    refute project.can_delete?(user)

    project = FactoryBot.create(:project)
    FactoryBot.create(:publication, projects:[project])
    project.work_groups.clear
    project.reload
    refute_empty project.publications
    refute project.can_delete?(user)
  end

  test 'gatekeepers' do
    User.with_current_user(FactoryBot.create(:admin)) do
      person = FactoryBot.create(:person_in_multiple_projects)
      assert_equal 3, person.projects.count
      proj1 = person.projects.first
      proj2 = person.projects.last
      person.is_asset_gatekeeper = true, proj1
      person.save!

      assert proj1.asset_gatekeepers.include?(person)
      assert !proj2.asset_gatekeepers.include?(person)
    end
  end

  test 'project_administrators' do
    User.with_current_user(FactoryBot.create(:admin)) do
      person = FactoryBot.create(:person_in_multiple_projects)
      proj1 = person.projects.first
      proj2 = person.projects.last
      person.is_project_administrator = true, proj1
      person.save!

      assert proj1.project_administrators.include?(person)
      assert !proj2.project_administrators.include?(person)
    end
  end

  test 'asset_managers' do
    User.with_current_user(FactoryBot.create(:admin)) do
      person = FactoryBot.create(:person_in_multiple_projects)
      proj1 = person.projects.first
      proj2 = person.projects.last
      person.is_asset_housekeeper = true, proj1
      person.save!

      assert proj1.asset_housekeepers.include?(person)
      assert !proj2.asset_housekeepers.include?(person)
    end
  end

  test 'pals' do
    User.with_current_user(FactoryBot.create(:admin)) do
      person = FactoryBot.create(:person_in_multiple_projects)
      proj1 = person.projects.first
      proj2 = person.projects.last
      person.is_pal = true, proj1
      person.save!

      assert proj1.pals.include?(person)
      assert !proj2.pals.include?(person)
    end
  end

  test 'without programme' do
    p1 = FactoryBot.create(:project)
    p2 = FactoryBot.create(:project, programme: FactoryBot.create(:programme))
    ps = Project.without_programme
    assert_includes ps, p1
    refute_includes ps, p2
  end

  test 'can create?' do
    User.current_user = nil
    refute Project.can_create?

    User.current_user = FactoryBot.create(:person).user
    refute Project.can_create?

    User.current_user = FactoryBot.create(:project_administrator).user
    refute Project.can_create?

    User.current_user = FactoryBot.create(:admin).user
    assert Project.can_create?

    person = FactoryBot.create(:programme_administrator)
    User.current_user = person.user
    programme = person.administered_programmes.first
    assert programme.is_activated?
    assert Project.can_create?

    # only if the programme is activated
    person = FactoryBot.create(:programme_administrator)
    programme = person.administered_programmes.first
    programme.is_activated = false
    disable_authorization_checks { programme.save! }
    User.current_user = person.user
    refute Project.can_create?
  end

  test 'project programmes' do
    project = FactoryBot.create(:project)
    assert_empty project.programmes
    assert_nil project.programme

    prog = FactoryBot.create(:programme)
    project = prog.projects.first
    assert_equal [prog], project.programmes
  end

  test 'mass assignment' do
    # check it is possible to mass assign all the attributes
    programme = FactoryBot.create(:programme)
    institution = FactoryBot.create(:institution)
    person = FactoryBot.create(:person)
    organism = FactoryBot.create(:organism)
    other_project = FactoryBot.create(:project)

    attr = {
      title: 'My Project',
      wiki_page: 'http://wikipage.com',
      web_page: 'http://webpage.com',
      organism_ids: [organism.id],
      institution_ids: [institution.id],
      description: 'Project description'
    }

    project = Project.create(attr)
    disable_authorization_checks { project.save! }
    project.reload

    assert_includes project.organisms, organism
    assert_equal 'Project description', project.description
    assert_equal 'http://wikipage.com', project.wiki_page
    assert_equal 'http://webpage.com', project.web_page
    assert_equal 'My Project', project.title

    # people with special roles need setting after the person belongs to the project,
    # otherwise non-members are stripped out when assigned
    person.add_to_project_and_institution(project, FactoryBot.create(:institution))
    person.save!
    person.reload

    attr = {
      project_administrator_ids: [person.id],
      asset_gatekeeper_ids: [person.id],
      pal_ids: [person.id],
      asset_housekeeper_ids: [person.id]
    }
    disable_authorization_checks { project.update(attr) }

    assert_includes project.project_administrators, person
    assert_includes project.asset_gatekeepers, person
    assert_includes project.pals, person
    assert_includes project.asset_housekeepers, person
  end

  test 'project role removed when removed from project' do
    project_administrator = FactoryBot.create(:project_administrator).reload
    project = project_administrator.projects.first

    assert_includes project_administrator.role_names, 'project_administrator'
    assert_includes project.project_administrators, project_administrator
    assert project_administrator.is_project_administrator?(project)
    assert project_administrator.user.is_project_administrator?(project)
    assert project_administrator.user.person.is_project_administrator?(project)
    assert project.can_manage?(project_administrator.user)

    project_administrator.group_memberships.destroy_all
    project_administrator = project_administrator.reload

    assert_not_includes project_administrator.role_names, 'project_administrator'
    assert_not_includes project.project_administrators, project_administrator
    assert !project_administrator.is_project_administrator?(project)
    assert !project.can_manage?(project_administrator.user)
  end

  test 'project role removed when marked as left project' do
    project_administrator = FactoryBot.create(:project_administrator).reload
    project = project_administrator.projects.first

    assert_includes project_administrator.role_names, 'project_administrator'
    assert_includes project.project_administrators, project_administrator
    assert project_administrator.is_project_administrator?(project)
    assert project_administrator.user.is_project_administrator?(project)
    assert project_administrator.user.person.is_project_administrator?(project)
    assert project.can_manage?(project_administrator.user)

    project_administrator.group_memberships.first.update(time_left_at: 1.day.ago)
    project_administrator = project_administrator.reload

    assert_not_includes project_administrator.role_names, 'project_administrator'
    assert_not_includes project.project_administrators, project_administrator
    assert !project_administrator.is_project_administrator?(project)
    assert !project.can_manage?(project_administrator.user)
  end

  test 'stores project settings' do
    project = FactoryBot.create(:project)

    assert_nil project.settings['nels_enabled']

    assert_difference('Settings.count') do
      project.settings['nels_enabled'] = true
    end

    assert project.settings['nels_enabled']
  end

  test 'sets project settings using virtual attributes' do
    project = FactoryBot.create(:project)

    assert_nil project.nels_enabled

    assert_difference('Settings.count') do
      project.update(nels_enabled: true)
    end

    assert project.nels_enabled
  end

  test 'does not use global defaults for project settings' do
    project = FactoryBot.create(:project)

    assert Settings.defaults.key?('nels_enabled')

    assert_nil Settings.for(project).fetch('nels_enabled')

    assert_nil project.settings['nels_enabled']
  end

  test 'stores encrypted project settings' do
    project = FactoryBot.create(:project)

    assert_nil project.settings['site_password']

    assert_difference('Settings.count') do
      project.settings['site_password'] = 'p@ssw0rd!'
    end

    setting = project.settings.where(var: 'site_password').first

    refute_equal 'p@ssw0rd!', setting[:encrypted_value]
    assert_nil setting[:value] # This is the database value
    assert_equal 'p@ssw0rd!',  setting.value
    assert_equal 'p@ssw0rd!',  project.settings['site_password']
  end

  test 'sets NeLS enabled in various ways' do
    project = FactoryBot.create(:project)

    assert_nil project.nels_enabled

    project.nels_enabled = true
    assert_equal true, project.reload.nels_enabled

    project.nels_enabled = false
    assert_equal false, project.reload.nels_enabled

    project.nels_enabled = '1'
    assert_equal true, project.reload.nels_enabled

    project.nels_enabled = '0'
    assert_equal false, project.reload.nels_enabled

    project.nels_enabled = false
    assert_equal false, project.reload.nels_enabled

    project.nels_enabled = 'yes please'
    assert_equal true, project.reload.nels_enabled
  end

  test 'funding code' do
    person = FactoryBot.create(:project_administrator)
    proj = person.projects.first
    User.with_current_user person.user do
      proj.funding_codes='fish'
      assert_equal ['fish'],proj.funding_codes.sort
      proj.save!
      proj=Project.find(proj.id)
      assert_equal ['fish'],proj.funding_codes.sort

      proj.funding_codes='1,2,3'
      assert_equal ['1','2','3'],proj.funding_codes.sort
      proj.save!
      proj=Project.find(proj.id)
      assert_equal ['1','2','3'],proj.funding_codes.sort

      proj.update_attribute(:funding_codes,'a,b')
      assert_equal ['a','b'],proj.funding_codes.sort
    end
  end

  test 'project assets' do
    disable_authorization_checks do
      assay = FactoryBot.create(:assay)
      project = assay.projects.first
      df = FactoryBot.create(:data_file, projects:[project])
      assay.data_files << df
      assay.save!

      assert project.assets.include? df
      refute project.project_assets.include? df

      unused_df = FactoryBot.create(:data_file, projects:[project])
      assert unused_df.investigations.empty?

      project.reload

      assert project.assets.include? unused_df
      assert project.project_assets.include? unused_df
    end
  end

  test 'ontology annotation properties'do
    project = FactoryBot.create(:project)

    assert project.supports_controlled_vocab_annotations?
    assert project.supports_controlled_vocab_annotations?(:topics)
    refute project.supports_controlled_vocab_annotations?(:operations)
    refute project.supports_controlled_vocab_annotations?(:data_formats)
    refute project.supports_controlled_vocab_annotations?(:data_types)

    assert project.respond_to?(:topic_annotations)
    refute project.respond_to?(:operation_annotations)
    refute project.respond_to?(:data_format_annotations)
    refute project.respond_to?(:data_type_annotation)

    FactoryBot.create(:topics_controlled_vocab) unless SampleControlledVocab::SystemVocabs.topics_controlled_vocab
    refute project.controlled_vocab_annotations?
    project.topic_annotations = 'Chemistry'
    assert project.controlled_vocab_annotations?
  end

  test 'total asset size includes blobs and git repos without duplication' do
    project = FactoryBot.create(:project)
    df = FactoryBot.create(:data_file, projects: [project])
    workflow1 = FactoryBot.create(:local_git_workflow, projects: [project])
    workflow2 = FactoryBot.create(:local_git_workflow, projects: [project])
    repo_size = 116994  # repo_size = `du -bs #{workflow1.local_git_repository.local_path}`.split("\t").first.to_i
    df_blob_size = 8827 # df_blob_size = df.content_blob.file_size

    assert_equal 1, workflow2.git_versions.length
    one_version_size = project.total_asset_size

    disable_authorization_checks { workflow2.save_as_new_git_version }
    assert_equal 2, workflow2.git_versions.length
    assert_equal workflow2.git_versions.first.git_repository.local_path, workflow2.git_versions.last.git_repository.local_path

    assert_equal one_version_size, project.total_asset_size, "total_asset_size is the same before and after adding a new version"
    assert_equal df_blob_size + 2 * repo_size, project.total_asset_size, "total_asset_size includes each workflow and df"
  end

end
