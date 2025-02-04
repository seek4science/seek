require 'test_helper'

class PersonTest < ActiveSupport::TestCase
  fixtures :users, :people, :roles

  def test_work_groups
    p = FactoryBot.create(:person_in_multiple_projects)
    assert_equal 3, p.work_groups.size
  end

  test 'supports extended metadata?' do
    refute Person.supports_extended_metadata?
    refute Person.new.supports_extended_metadata?
  end

  test 'to_json_ld' do
    refute_nil JSON.parse(FactoryBot.create(:person).to_json_ld)
  end

  test 'to schema ld' do
    p = FactoryBot.create(:person)
    assert p.schema_org_supported?
  end

  test "registered user's profile can be edited by" do
    admin = FactoryBot.create(:admin)
    project_administrator = FactoryBot.create(:project_administrator)
    project_administrator2 = FactoryBot.create(:project_administrator)
    person = FactoryBot.create :person, group_memberships: [FactoryBot.create(:group_membership, work_group: project_administrator.group_memberships.first.work_group)]
    another_person = FactoryBot.create :person

    assert_equal person.projects, project_administrator.projects
    assert_not_equal person.projects, project_administrator2.projects

    assert person.can_edit?(person.user)
    refute person.can_edit?(project_administrator.user), 'should not be editable by the project administrator of the same project, as user is registered'
    assert person.can_edit?(admin.user)
    refute person.can_edit?(another_person.user)
    refute person.can_edit?(project_administrator2.user), 'should be not editable by the project administrator of another project'

    assert person.can_edit?(person), 'You can also ask by passing in a person'
    refute person.can_edit?(project_administrator), 'You can also ask by passing in a person'
  end

  test 'userless profile can be edited by' do
    admin = FactoryBot.create(:admin)
    project_administrator = FactoryBot.create(:project_administrator)
    project_administrator2 = FactoryBot.create(:project_administrator)
    profile = FactoryBot.create :brand_new_person, group_memberships: [FactoryBot.create(:group_membership, work_group: project_administrator.group_memberships.first.work_group)]
    another_person = FactoryBot.create :person

    assert_equal profile.projects, project_administrator.projects
    assert_not_equal profile.projects, project_administrator2.projects

    assert profile.can_edit?(project_administrator.user), 'should be editable by the project administrator of the same project, as user is not registered'
    assert profile.can_edit?(admin.user)
    refute profile.can_edit?(another_person.user)
    refute profile.can_edit?(project_administrator2.user), 'should be not editable by the project administrator of another project'

    assert profile.can_edit?(project_administrator), 'You can also ask by passing in a person'
  end

  test 'me?' do
    person = FactoryBot.create(:person)
    refute person.me?
    User.current_user = person.user
    assert person.me?
    person = FactoryBot.create(:brand_new_person)
    assert_nil person.user
    refute person.me?
    User.current_user = nil
    refute person.me?
  end

  test 'programmes' do
    person1 = FactoryBot.create(:person)
    prog = FactoryBot.create(:programme, projects: person1.projects)
    prog2 = FactoryBot.create(:programme)
    assert_includes person1.programmes, prog
    refute_includes person1.programmes, prog2
  end

  test 'show related empty programmes' do
    person1 = FactoryBot.create(:programme_administrator_not_in_project)
    person2 = FactoryBot.create(:programme_administrator_not_in_project)
    person3 = FactoryBot.create(:programme_administrator_not_in_project) # Programme administrator not in empty_programme1
    empty_programme1 = FactoryBot.create(:min_programme, programme_administrators: [person1, person2])

    [person1, person2].each do |p|
      assert_includes p.related_programmes, empty_programme1
    end
    refute_includes person3.related_programmes, empty_programme1

    person4 = FactoryBot.create(:person_in_project) # Member of a project in prog 2, not a programme administrator
    prog2 = FactoryBot.create(:programme, projects: person4.projects, programme_administrators: [person1, person3])

    [person1, person3, person4].each do |p|
      assert_includes p.related_programmes, prog2
    end
  end

  test 'can be administered by' do
    admin = FactoryBot.create(:admin)
    admin2 = FactoryBot.create(:admin)
    project_administrator = FactoryBot.create(:project_administrator)
    person_in_same_project = FactoryBot.create :person, group_memberships: [FactoryBot.create(:group_membership, work_group: project_administrator.group_memberships.first.work_group)]
    person_in_different_project = FactoryBot.create :person

    assert admin.can_manage?(admin.user), 'admin can administer themself'
    assert admin2.can_manage?(admin.user), 'admin can administer another admin'

    assert project_administrator.can_manage?(admin.user), 'admin should be able to administer another project administrator'
    assert person_in_same_project.can_manage?(project_administrator.user), 'project administrator should be able to administer someone from same project'
    assert person_in_different_project.can_manage?(project_administrator.user), 'project administrator should be able to administer someone from another project'

    refute project_administrator.can_manage?(person_in_same_project.user), 'a normal person cannot administer someone else'
    refute project_administrator.can_manage?(project_administrator.user), 'project administrator should not administer himself'
    refute person_in_same_project.can_manage?(person_in_same_project.user), 'person should not administer themself'
    refute person_in_same_project.can_manage?(nil)

    assert project_administrator.can_manage?(admin), 'you can also ask by passing a person'
    assert person_in_same_project.can_manage?(project_administrator), 'you can also ask by passing a person'

    # can be administered by a programme administrator
    pa = FactoryBot.create :programme_administrator
    assert FactoryBot.create(:person).can_manage?(pa.user)
  end

  test 'project administrator cannot edit an admin within their project' do
    admin = FactoryBot.create(:admin)
    project_administrator = FactoryBot.create(:project_administrator, group_memberships: [FactoryBot.create(:group_membership, work_group: admin.group_memberships.first.work_group)])

    refute (admin.projects & project_administrator.projects).empty?

    refute admin.can_edit?(project_administrator)
  end

  # checks the updated_at doesn't get artificially changed between created and reloading
  def test_updated_at
    person = FactoryBot.create(:person, updated_at: 1.week.ago)

    updated_at = person.updated_at
    person = Person.find(person.id)
    assert_equal updated_at.to_s, person.updated_at.to_s
  end

  test 'to_rdf' do
    object = FactoryBot.create :person, skype_name: 'skypee', email: 'sdkfhsd22fkhfsd@sdkfsdkhfkhsdf.com', web_page:'http://google.com'
    FactoryBot.create(:study, contributor: object)
    FactoryBot.create(:investigation, contributor: object)
    FactoryBot.create(:assay, contributor: object)
    assay = FactoryBot.create(:assay, contributor: object, creators:[object])
    presentation = FactoryBot.create(:assay, contributor:object, creators:[object])
    doc = FactoryBot.create(:document, contributor:object, creators:[object])
    sop = FactoryBot.create(:sop, creators:[object])

    assert_equal [object],assay.creators
    assert_equal [object],presentation.creators
    assert_equal [object],sop.creators
    assert_equal [object],doc.creators

    disable_authorization_checks do
      object.save!
    end
    object.reload
    rdf = object.to_rdf
    graph = RDF::Graph.new do |graph|
      RDF::Reader.for(:ttl).new(rdf) {|reader| graph << reader}
    end
    assert graph.statements.count > 1
    assert_equal RDF::URI.new("http://localhost:3000/people/#{object.id}"), graph.statements.first.subject
    assert graph.has_triple? ["http://localhost:3000/people/#{object.id}", RDF::Vocab::FOAF.mbox_sha1sum, 'b507549e01d249ee5ed98bd40e4d86d1470a13b8']
    assert graph.has_triple? ["http://localhost:3000/people/#{object.id}", RDF::Vocab::FOAF.homepage, RDF::Literal::AnyURI.new('http://google.com')]

    #none rdf supported created items are filtered out
    assert graph.has_triple? ["http://localhost:3000/people/#{object.id}", Seek::Rdf::JERMVocab.isCreatorOf, "http://localhost:3000/assays/#{assay.id}"]
    assert graph.has_triple? ["http://localhost:3000/people/#{object.id}", Seek::Rdf::JERMVocab.isCreatorOf, "http://localhost:3000/sops/#{sop.id}"]
    refute graph.has_triple? ["http://localhost:3000/people/#{object.id}", Seek::Rdf::JERMVocab.isCreatorOf, "http://localhost:3000/documents/#{doc.id}"]
    refute graph.has_triple? ["http://localhost:3000/people/#{object.id}", Seek::Rdf::JERMVocab.isCreatorOf, "http://localhost:3000/presentations/#{presentation.id}"]

  end

  test 'contributed items' do
    person = FactoryBot.create(:person)
    refute_nil person.user
    assert_empty person.contributed_items

    df = FactoryBot.create(:data_file, contributor: person)
    inv = FactoryBot.create(:investigation, contributor:person)
    study = FactoryBot.create(:study, contributor: person,investigation:inv)
    as = FactoryBot.create(:assay, contributor: person,study:study)
    strain = FactoryBot.create(:strain,contributor:person)
    sample = FactoryBot.create(:sample,contributor:person)

    items = person.reload.contributed_items

    assert_equal 6, items.count
    assert_includes items, df
    assert_includes items, as
    assert_includes items, study
    assert_includes items, inv
    assert_includes items, strain
    assert_includes items, sample

    person = FactoryBot.create(:person_in_project)
    assert_nil person.user

    assert_empty person.reload.contributed_items

    df = FactoryBot.create(:data_file, contributor: person)
    inv = FactoryBot.create(:investigation, contributor:person)
    study = FactoryBot.create(:study, contributor: person,investigation:inv)
    as = FactoryBot.create(:assay, contributor: person,study:study)

    items = person.reload.contributed_items

    assert_equal 4, items.count
    assert_includes items, df
    assert_includes items, as
    assert_includes items, inv
  end

  test 'orcid id validation' do
    p = FactoryBot.create :person
    p.orcid = nil
    assert p.valid?
    p.orcid = 'sdff-1111-1111-1111'
    refute p.valid?
    p.orcid = '1111111111111111'
    refute p.valid?
    p.orcid = '0000-0002-1694-2339'
    refute p.valid?, "checksum doesn't match"
    p.orcid = '0000-0002-1694-233X'
    assert p.valid?
    p.orcid = 'http://orcid.org/0000-0002-1694-233X'
    assert p.valid?
    p.orcid = 'http://orcid.org/0000-0003-2130-0865'
    assert p.valid?

    p.orcid = 'https://orcid.org/0000-0003-2130-0865'
    assert p.valid?
  end

  test 'orcid_uri' do
    disable_authorization_checks do
      p = FactoryBot.create :person
      p.orcid = 'http://orcid.org/0000-0003-2130-0865'
      assert p.valid?
      p.save!
      p.reload
      assert_equal 'https://orcid.org/0000-0003-2130-0865', p.orcid_uri

      p.orcid = '0000-0002-1694-233X'
      p.save!
      p.reload
      assert_equal 'https://orcid.org/0000-0002-1694-233X', p.orcid_uri

      p.orcid = 'https://orcid.org/0000-0002-1694-233X'
      p.save!
      p.reload
      assert_equal 'https://orcid.org/0000-0002-1694-233X', p.orcid_uri

      p.orcid = nil
      p.save!
      p.reload
      assert_nil p.orcid_uri

      p.orcid = ''
      p.save!
      p.reload
      assert_nil p.orcid_uri
    end
  end


  test 'orcid display format' do
    p = FactoryBot.create :person, orcid: 'http://orcid.org/0000-0003-2130-0865'
    assert_equal 'https://orcid.org/0000-0003-2130-0865', p.orcid_display_format

    p = FactoryBot.create :person
    assert_nil p.orcid_display_format
  end

  test 'email uri' do
    p = FactoryBot.create :person, email: 'sfkh^sd@weoruweoru.com'
    assert_equal 'mailto:sfkh%5Esd@weoruweoru.com', p.email_uri
  end

  test 'mbox_sha1sum' do
    p = FactoryBot.create :person, email: 'sfkh^sd@weoruweoru.com'
    assert_equal '60f787c78d77437f192d8ebce5ee4ece7cbaaca6',p.mbox_sha1sum
  end

  test 'only first admin person' do
    Person.delete_all
    person = FactoryBot.create :admin
    assert person.only_first_admin_person?

    disable_authorization_checks { person.save! }
    person.is_admin = false
    refute person.only_first_admin_person?
    person.is_admin = true
    disable_authorization_checks { person.save! }
    assert person.only_first_admin_person?
    FactoryBot.create :person
    refute person.only_first_admin_person?
  end

  def test_active_ordered_by_updated_at_and_avatar_not_null
    Person.delete_all

    avatar = FactoryBot.create :avatar

    people = []

    people << FactoryBot.create(:person, avatar: avatar, updated_at: 1.week.ago)
    people << FactoryBot.create(:person, avatar: avatar, updated_at: 1.minute.ago)
    people << FactoryBot.create(:person, updated_at: 1.day.ago)
    people << FactoryBot.create(:person, updated_at: 1.hour.ago)
    people << FactoryBot.create(:person, updated_at: 2.minutes.ago)

    sorted = Person.all.sort do |x, y|
      if x.avatar.nil? == y.avatar.nil?
        y.updated_at <=> x.updated_at
      else
        if x.avatar.nil?
          1
        else
          -1
        end
      end
    end

    assert_equal sorted, Person.active
  end

  def test_is_asset
    refute Person.is_asset?
    refute people(:quentin_person).is_asset?
    refute people(:quentin_person).is_downloadable_asset?
  end

  def test_member_of
    p = FactoryBot.create :person
    proj = FactoryBot.create :project
    refute p.projects.empty?
    assert p.member_of?(p.projects.first)
    refute p.member_of?(proj)
  end

  def test_avatar_key
    p = people(:quentin_person)
    assert_nil p.avatar_key
    assert p.defines_own_avatar?
  end

  def test_first_person_is_admin
    assert Person.count > 0 # should already be people from fixtures
    p = FactoryBot.create(:brand_new_person, first_name: 'XXX', email: 'xxx@email.com')
    refute p.is_admin?, 'Should not automatically be admin, since people already exist'

    Person.delete_all

    assert_equal 0, Person.count # no people should exist
    p = FactoryBot.create(:brand_new_person, first_name: 'XXX', email: 'xxx@email.com')
    p.save
    p.reload
    assert p.is_admin?, 'Should automatically be admin, since it is the first created person'
  end

  test 'first person in default project' do
    FactoryBot.create(:person) # make sure there is a person, project and institution registered

    assert Person.count > 0
    assert Project.count > 0
    p = FactoryBot.create(:brand_new_person, first_name: 'XXX', email: 'xxx@email.com')
    refute p.is_admin?, 'Should not automatically be admin, since people already exist'
    assert_empty p.projects
    assert_empty p.institutions

    Person.delete_all

    project = Project.first
    institution = project.institutions.first
    refute_nil project
    refute_nil institution

    assert_equal 0, Person.count # no people should exist
    p = FactoryBot.create(:brand_new_person, first_name: 'XXX', email: 'xxx@email.com')
    p.reload
    assert_equal [project], p.projects
    assert_equal [institution], p.institutions
  end

  def test_registered
    registered = Person.registered
    registered.each do |p|
      refute_nil p.user
    end
    assert registered.include?(people(:quentin_person))
    refute registered.include?(people(:person_without_user))
  end

  def test_duplicates
    dups = Person.duplicates
    refute dups.empty?
    assert dups.include?(people(:duplicate_1))
    assert dups.include?(people(:duplicate_2))
  end

  test 'without group' do
    no_group = FactoryBot.create(:brand_new_person)
    in_group = FactoryBot.create(:person)
    assert no_group.projects.empty?
    refute in_group.projects.empty?
    all = Person.without_group
    refute all.include?(in_group)
    assert all.include?(no_group)
  end

  test 'with group' do
    no_group = FactoryBot.create(:brand_new_person)
    in_group = FactoryBot.create(:person)
    assert no_group.projects.empty?
    refute in_group.projects.empty?
    all = Person.with_group
    assert all.include?(in_group)
    refute all.include?(no_group)
  end

  def test_expertise
    p = FactoryBot.create :person
    FactoryBot.create :expertise, value: 'golf', annotatable: p
    FactoryBot.create :expertise, value: 'fishing', annotatable: p
    FactoryBot.create :tool, value: 'sbml', annotatable: p

    assert_equal 2, p.expertise.size

    p = FactoryBot.create :person
    FactoryBot.create :expertise, value: 'golf', annotatable: p
    FactoryBot.create :tool, value: 'sbml', annotatable: p
    assert_equal 1, p.expertise.size
    assert_equal 'golf', p.expertise[0]
  end

  def test_tools
    p = FactoryBot.create :person
    FactoryBot.create :tool, value: 'sbml', annotatable: p
    FactoryBot.create :tool, value: 'java', annotatable: p
    FactoryBot.create :expertise, value: 'sbml', annotatable: p

    assert_equal 2, p.tools.size

    p = FactoryBot.create :person
    FactoryBot.create :tool, value: 'sbml', annotatable: p
    FactoryBot.create :expertise, value: 'fishing', annotatable: p
    assert_equal 1, p.tools.size
    assert_equal 'sbml', p.tools[0]
  end

  def test_assign_expertise
    p = FactoryBot.create :person
    User.with_current_user p.user do
      assert_equal 0, p.expertise.size
      assert_difference('Annotation.count', 2) do
        assert_difference('TextValue.count', 2) do
          p.expertise = %w[golf fishing]
          p.save!
        end
      end

      assert_equal 2, p.expertise.size
      assert p.expertise.include?('golf')
      assert p.expertise.include?('fishing')

      assert_difference('Annotation.count', -1) do
        assert_no_difference('TextValue.count') do
          p.expertise = ['golf']
          p.save!
        end
      end

      assert_equal 1, p.expertise.size
      assert_equal 'golf', p.expertise[0]

      p2 = FactoryBot.create :person
      assert_difference('Annotation.count') do
        assert_no_difference('TextValue.count') do
          p2.expertise = ['golf']
          p2.save!
        end
      end
    end
  end

  def test_assigns_tools
    p = FactoryBot.create :person
    User.with_current_user p.user do
      assert_equal 0, p.tools.size
      assert_difference('Annotation.count', 2) do
        assert_difference('TextValue.count', 2) do
          p.tools = %w[golf fishing]
          p.save!
        end
      end

      assert_equal 2, p.tools.size
      assert p.tools.include?('golf')
      assert p.tools.include?('fishing')

      assert_difference('Annotation.count', -1) do
        assert_no_difference('TextValue.count') do
          p.tools = ['golf']
          p.save!
        end
      end

      assert_equal 1, p.tools.size
      assert_equal 'golf', p.tools[0]

      p2 = FactoryBot.create :person
      assert_difference('Annotation.count') do
        assert_no_difference('TextValue.count') do
          p2.tools = ['golf']
          p2.save!
        end
      end
    end
  end

  def test_removes_previously_assigned
    p = FactoryBot.create :person
    User.with_current_user p.user do
      p.tools = %w[one two]
      assert_equal 2, p.tools.size
      p.tools = ['three']
      assert_equal 1, p.tools.size
      assert_equal 'three', p.tools[0]

      p = FactoryBot.create :person
      p.expertise = %w[aaa bbb]
      assert_equal 2, p.expertise.size
      p.expertise = ['ccc']
      assert_equal 1, p.expertise.size
      assert_equal 'ccc', p.expertise[0]
    end
  end

  def test_expertise_and_tools_with_same_name
    p = FactoryBot.create :person
    User.with_current_user p.user do
      assert_difference('Annotation.count', 2) do
        assert_difference('TextValue.count', 2) do
          p.tools = %w[golf fishing]
          p.save!
        end
      end

      assert_difference('Annotation.count', 2) do
        assert_no_difference('TextValue.count') do
          p.expertise = %w[golf fishing]
          p.save!
        end
      end
    end
  end

  def test_institutions
    person = FactoryBot.create(:person_in_multiple_projects)

    institution = person.group_memberships.first.work_group.institution
    institution2 = FactoryBot.create(:institution)

    assert_equal 3, person.institutions.count
    assert person.institutions.include?(institution)
    refute person.institutions.include?(institution2)
  end

  def test_projects
    p = FactoryBot.create(:person_in_multiple_projects)
    assert_equal 3, p.projects.size
  end

  test 'not registered' do
    peeps = Person.not_registered
    refute_nil peeps
    refute peeps.empty?, 'There should be some userless people'
    assert_nil(peeps.find { |p| !p.user.nil? }, 'There should be no people with a non nil user')

    p = people(:three)
    refute_nil(peeps.find { |person| p.id == person.id }, 'Person :three should be userless and therefore in the list')

    p = people(:quentin_person)
    assert_nil(peeps.find { |person| p.id == person.id }, 'Person :one should have a user and not be in the list')
  end

  def test_name
    p = people(:quentin_person)
    assert_equal 'Quentin Jones', p.name
    p.first_name = 'Tom'
    assert_equal 'Tom Jones', p.name
  end

  def test_email_with_name
    p = people(:quentin_person)
    assert_equal('Quentin Jones <quentin@email.com>', p.email_with_name)
  end

  def test_email_with_name_no_last_name
    p = Person.new(first_name: 'Fred', email: 'fff@fff.com')
    assert_equal('Fred <fff@fff.com>', p.email_with_name)
  end

  def test_capitalization_with_nil_last_name
    p = people(:no_first_name)
    assert_equal 'Lastname', p.name
  end

  def test_capitalization_with_nil_first_name
    p = people(:no_last_name)
    assert_equal 'Firstname', p.name
  end

  def test_double_firstname_capitalised
    p = people(:double_firstname)
    assert_equal 'Fred David Bloggs', p.name
  end

  def test_double_lastname_capitalised
    p = people(:double_lastname)
    assert_equal 'Fred Smith Jones', p.name
  end

  def test_double_barrelled_lastname_capitalised
    p = people(:double_barrelled_lastname)
    assert_equal 'Fred Smith-Jones', p.name
  end

  def test_valid
    p = people(:quentin_person)
    assert p.valid?
    p.email = nil
    refute p.valid?

    p.email = 'sdf'
    refute p.valid?

    p.email = 'sdf@'
    refute p.valid?

    p.email = 'sdaf@sdf.com'
    assert p.valid?

    p.web_page = nil
    assert p.valid?

    p.web_page = ''
    assert p.valid?

    p.web_page = 'sdfsdf'
    refute p.valid?

    p.web_page = 'http://google.com'
    assert p.valid?

    p.web_page = 'https://google.com'
    assert p.valid?

    p.web_page = 'http://google.com/fred'
    assert p.valid?

    p.web_page = 'http://google.com/fred?param=bob'
    assert p.valid?

    p.web_page = 'http://www.mygrid.org.uk/dev/issues/secure/IssueNavigator.jspa?reset=true&mode=hide&sorter/order=DESC&sorter/field=priority&resolution=-1&pid=10051&fixfor=10110'
    assert p.valid?
  end

  test 'sensible validation error for no name' do
    assert FactoryBot.create(:person,first_name:'').valid?
    assert FactoryBot.create(:person,last_name:'').valid?
    p = FactoryBot.build(:person,first_name:'',last_name:'')
    refute p.valid?
    assert_equal 1,p.errors.full_messages.count
    assert_equal "Full name can't be blank",p.errors.full_messages.first
  end

  def test_email_with_capitalise_valid
    p = people(:quentin_person)
    assert p.valid?
    p.email = 'gordon.brown@gov.uk'
    assert p.valid?
    p.email = 'Gordon.Brown@gov.uk'
    assert p.valid?, 'Capitals in email should be valid'
  end

  def test_email_unique
    p = people(:quentin_person)
    newP = Person.new(first_name: 'Fred', email: p.email)
    refute newP.valid?, 'Should not be valid as email is not unique'
    newP.email = p.email.capitalize
    refute newP.valid?, 'Should not be valid as email is not case sensitive'
    newP.email = 'zxczxc@zxczxczxc.com'
    assert newP.valid?
  end

  def test_disciplines
    p = FactoryBot.create :person, disciplines: [FactoryBot.create(:discipline, title: 'A'), FactoryBot.create(:discipline, title: 'B')]
    p.reload
    assert_equal 2, p.disciplines.size
    assert_equal 'A', p.disciplines[0].title
    assert_equal 'B', p.disciplines[1].title
  end

  def test_update_first_letter
    p = FactoryBot.create(:brand_new_person, first_name: 'Fred', last_name: 'Monkhouse', email: 'blahblah@email.com')
    assert p.valid?, 'The new person should be valid'
    assert_equal 'M', p.first_letter

    p = FactoryBot.create(:brand_new_person, first_name: 'Freddy', last_name: nil, email: 'blahbddlah@email.com')
    assert p.valid?, 'The new person should be valid'
    assert_equal 'F', p.first_letter

    p = FactoryBot.create(:brand_new_person, first_name: 'Zebedee', last_name: nil, email: 'zz@email.com')
    assert p.valid?, 'The new person should be valid'
    assert_equal 'Z', p.first_letter
  end

  def test_update_first_letter_blank_last_name
    p = FactoryBot.create(:brand_new_person, first_name: 'Zebedee', last_name: '', email: 'zz@email.com')
    assert p.valid?, 'The new person should be valid'
    assert_equal 'Z', p.first_letter
  end

  def test_notifiee_info_inserted
    p = FactoryBot.build(:brand_new_person, first_name: 'Zebedee', last_name: '', email: 'zz@email.com')
    assert_nil p.notifiee_info
    assert_difference('NotifieeInfo.count') do
      disable_authorization_checks { p.save! }
    end
    p = Person.find(p.id)
    refute_nil p.notifiee_info
    assert p.receive_notifications?
  end

  def test_dependent_notifiee_info_is_destroyed_with_person
    p = FactoryBot.create(:brand_new_person, first_name: 'Zebedee', last_name: '', email: 'zz@email.com')
    refute_nil p.notifiee_info
    assert_difference('NotifieeInfo.count', -1) do
      disable_authorization_checks { p.destroy }
    end
  end

  def test_user_is_destroyed_with_person
    p = people(:quentin_person)
    u = users(:quentin)
    assert_difference('Person.count', -1) do
      assert_difference('User.count', -1) do
        disable_authorization_checks { p.destroy }
      end
    end
    assert_nil User.find_by_id(u.id)

    p = people(:random_userless_person)
    assert_difference('Person.count', -1) do
      assert_no_difference('User.count') do
        disable_authorization_checks { p.destroy }
      end
    end
  end

  def test_updated_not_changed_when_adding_notifiee_info
    p = people(:modeller_person)
    up_at = p.updated_at
    sleep(2)
    p.check_for_notifiee_info
    assert_equal up_at, p.updated_at
  end

  test 'test uuid generated' do
    p = people(:modeller_person)
    assert_nil p.attributes['uuid']
    p.save
    refute_nil p.attributes['uuid']
  end

  test "uuid doesn't change" do
    x = people(:modeller_person)
    x.save
    uuid = x.attributes['uuid']
    x.save
    assert_equal x.uuid, uuid
  end

  test 'should retrieve the list of people who have the manage right on the item' do
    user = FactoryBot.create(:user)
    person = user.person
    data_file = FactoryBot.create(:data_file, contributor: person)
    people_can_manage = data_file.people_can_manage
    assert_equal 1, people_can_manage.count
    assert_equal person.id, people_can_manage.first[0]

    new_person = FactoryBot.create(:person_in_project)
    policy = data_file.policy
    policy.permissions.build(contributor: new_person, access_type: Policy::MANAGING)
    policy.save
    people_can_manage = data_file.people_can_manage
    assert_equal 2, people_can_manage.count
    people_ids = people_can_manage.collect { |p| p[0] }
    assert people_ids.include? person.id
    assert people_ids.include? new_person.id
  end

  test 'related resource' do
    user = FactoryBot.create :user
    person = user.person
    User.with_current_user(user) do
      AssetsCreator.create asset: FactoryBot.create(:data_file), creator: person
      AssetsCreator.create asset: FactoryBot.create(:model), creator: person
      AssetsCreator.create asset: FactoryBot.create(:sop), creator: person
      event = FactoryBot.create :event, contributor: person
      AssetsCreator.create asset: FactoryBot.create(:presentation), creator: person
      AssetsCreator.create asset: FactoryBot.create(:publication), creator: person
      assert_equal person.created_data_files, person.related_data_files
      assert_equal person.created_models, person.related_models
      assert_equal person.created_sops, person.related_sops
      assert_equal [event], person.related_events
      assert_equal person.created_presentations, person.related_presentations
      assert_equal person.created_publications, person.related_publications
    end
  end

  test 'related isa' do
    person = FactoryBot.create(:person)

    AssetsCreator.create asset: (inv1 = FactoryBot.create(:investigation)), creator: person
    inv2 = FactoryBot.create(:investigation, contributor: person)
    assert_equal [inv1, inv2].sort, person.related_investigations.sort

    AssetsCreator.create asset: (study1 = FactoryBot.create(:study)), creator: person
    study2 = FactoryBot.create(:study, contributor: person)
    assert_equal [study1, study2].sort, person.related_studies.sort

    AssetsCreator.create asset: (assay1 = FactoryBot.create(:assay)), creator: person
    assay2 = FactoryBot.create(:assay, contributor: person)
    assert_equal [assay1, assay2].sort, person.related_assays.sort
  end

  test 'related sample_type' do
    person1 = FactoryBot.create(:person)
    person2 = FactoryBot.create(:person)
    st1 = FactoryBot.create(:simple_sample_type, contributor: person1, creators: [person1])
    st2 = FactoryBot.create(:simple_sample_type, contributor: person1, creators: [person2])
    st3 = FactoryBot.create(:simple_sample_type, contributor: person2, creators: [person1])
    assert_equal [st1, st2, st3].sort, person1.related_sample_types.sort
  end

  test 'get the correct investigations and studies' do
    p = FactoryBot.create(:person)

    inv1 = FactoryBot.create(:investigation, contributor: p)

    study1 = FactoryBot.create(:study, contributor: p, investigation:inv1)
    study2 = FactoryBot.create(:study, contributor: p, investigation:inv1)
    p = Person.find(p.id)

    assert_equal [study1, study2], p.contributed_studies.sort_by(&:id)

    assert_equal [inv1], p.contributed_investigations
  end

  test 'should be able to remove the workgroup whose project is not subcribed' do
    p = FactoryBot.create :person
    wg = FactoryBot.create :work_group
    p.work_groups = [wg]

    p.project_subscriptions.delete_all
    assert p.project_subscriptions.empty?
    p.work_groups = []
    p.save
    assert_empty p.work_groups
    assert_empty p.projects
  end

  test 'add to project and institution subscribes to project' do
    person = FactoryBot.create :brand_new_person
    inst = FactoryBot.create(:institution)
    proj = FactoryBot.create(:project)

    assert_empty person.project_subscriptions
    person.add_to_project_and_institution(proj, inst)
    person.save!

    person.reload
    assert_includes person.project_subscriptions.map(&:project), proj
  end

  test 'shares programme?' do
    person1 = FactoryBot.create(:person)
    person2 = FactoryBot.create(:person)
    person3 = FactoryBot.create(:person)

    prog1 = FactoryBot.create :programme, projects: (person1.projects | person2.projects)
    prog2 = FactoryBot.create :programme, projects: person3.projects
    assert person1.shares_programme?(person2)
    assert person2.shares_programme?(person1)
    refute person3.shares_programme?(person1)
    refute person3.shares_programme?(person2)
    refute person1.shares_programme?(person3)
    refute person2.shares_programme?(person3)

    # also with project rather than person
    assert person1.shares_programme?(person2.projects.first)
    refute person2.shares_programme?(person3.projects.first)
  end

  test 'shares project?' do
    person1 = FactoryBot.create(:person)
    project = person1.projects.first
    person2 = FactoryBot.create(:person, work_groups: [project.work_groups.first])
    person3 = FactoryBot.create(:person)

    assert person1.shares_project?(person2)
    refute person1.shares_project?(person3)

    assert person1.shares_project?(project)
    refute person1.shares_project?(person3.projects.first)

    assert person1.shares_project?([project])
    assert person1.shares_project?([project, FactoryBot.create(:project)])
    refute person1.shares_project?([person3.projects.first])
    refute person1.shares_project?([person3.projects.first, FactoryBot.create(:project)])
  end

  test 'add to project and institution' do
    proj1 = FactoryBot.create :project
    proj2 = FactoryBot.create :project

    inst1 = FactoryBot.create :institution
    inst2 = FactoryBot.create :institution

    p1 = FactoryBot.create :brand_new_person
    p2 = FactoryBot.create :brand_new_person
    assert_difference('WorkGroup.count', 1) do
      assert_difference('GroupMembership.count', 1) do
        p1.add_to_project_and_institution(proj1, inst1)
        p1.save!
      end
    end
    p1.reload
    assert_equal 1, p1.projects.count
    assert_includes p1.projects, proj1
    assert_equal 1, p1.institutions.count
    assert_includes p1.institutions, inst1

    assert_no_difference('WorkGroup.count') do
      assert_difference('GroupMembership.count', 1) do
        p2.add_to_project_and_institution(proj1, inst1)
      end
    end

    p2.reload
    assert_equal 1, p2.projects.count
    assert_includes p2.projects, proj1
    assert_equal 1, p2.institutions.count
    assert_includes p2.institutions, inst1

    assert_difference('WorkGroup.count', 1) do
      assert_difference('GroupMembership.count', 1) do
        p1.add_to_project_and_institution(proj2, inst1)
      end
    end

    assert_difference('WorkGroup.count', 1) do
      assert_difference('GroupMembership.count', 1) do
        p1.add_to_project_and_institution(proj1, inst2)
      end
    end

    p1.reload
    assert_equal 2, p1.projects.count
    assert_includes p1.projects, proj2
    assert_equal 2, p1.institutions.count
    assert_includes p1.institutions, inst2

    assert_no_difference('WorkGroup.count') do
      assert_no_difference('GroupMembership.count') do
        p1.add_to_project_and_institution(proj1, inst1)
      end
    end
  end

  test 'add to project and institution saves new' do
    person = FactoryBot.create(:person)
    institution = Institution.new(title:'an institution')
    project = Project.new(title: 'a project')
    assert institution.valid?
    assert project.valid?

    disable_authorization_checks do
      assert_difference('Project.count') do
        assert_difference('Institution.count') do
          assert_difference('WorkGroup.count') do
            assert_difference('GroupMembership.count') do
              person.add_to_project_and_institution(project, institution)
            end
          end
        end
      end
    end

    # won't if the institution is invalid
    institution = Institution.new(title:nil)
    project = Project.new(title: 'another project')
    refute institution.valid?
    assert project.valid?

    disable_authorization_checks do
      assert_no_difference('Project.count') do
        assert_no_difference('Institution.count') do
          assert_no_difference('WorkGroup.count') do
            assert_no_difference('GroupMembership.count') do
              person.add_to_project_and_institution(project, institution)
            end
          end
        end
      end
    end

    # won't if the project is invalid
    institution = Institution.new(title:'another inst')
    project = Project.new(title: nil)
    assert institution.valid?
    refute project.valid?

    disable_authorization_checks do
      assert_no_difference('Project.count') do
        assert_no_difference('Institution.count') do
          assert_no_difference('WorkGroup.count') do
            assert_no_difference('GroupMembership.count') do
              person.add_to_project_and_institution(project, institution)
            end
          end
        end
      end
    end
  end

  test 'cache-key changes with workgroup' do
    person = FactoryBot.create :person
    refute_empty person.projects
    cachekey = person.cache_key
    person.add_to_project_and_institution(FactoryBot.create(:project), FactoryBot.create(:institution))
    refute_equal cachekey, person.cache_key
  end

  test 'can create' do
    User.current_user = FactoryBot.create(:project_administrator).user
    assert Person.can_create?

    User.current_user = FactoryBot.create(:admin).user
    assert Person.can_create?

    User.current_user = FactoryBot.create(:brand_new_user)
    refute User.current_user.registration_complete?
    assert Person.can_create?

    User.current_user = nil
    refute Person.can_create?

    User.current_user = FactoryBot.create(:person).user
    refute Person.can_create?

    User.current_user = FactoryBot.create(:pal).user
    refute Person.can_create?

    User.current_user = FactoryBot.create(:asset_gatekeeper).user
    refute Person.can_create?

    User.current_user = FactoryBot.create(:asset_housekeeper).user
    refute Person.can_create?

    User.current_user = FactoryBot.create(:programme_administrator).user
    assert Person.can_create?
  end

  test 'administered programmes' do
    pa = FactoryBot.create(:programme_administrator)
    admin = FactoryBot.create(:admin)
    other_prog = FactoryBot.create(:programme)
    progs = pa.programmes
    assert_equal progs.sort, pa.administered_programmes.sort
    refute_includes pa.administered_programmes, other_prog

    assert_empty FactoryBot.create(:person).administered_programmes
    assert_equal Programme.all.sort, admin.administered_programmes.sort
  end

  test 'not_registered_with_matching_email' do
    3.times do
      FactoryBot.create :person
    end
    p1 = FactoryBot.create :brand_new_person, email: 'FISH-sOup@email.com'
    p2 = FactoryBot.create :person, email: 'FISH-registered@email.com'

    refute p1.registered?
    assert p2.registered?

    assert_includes Person.not_registered_with_matching_email('FISH-sOup@email.com'), p1
    assert_includes Person.not_registered_with_matching_email('fish-soup@email.com'), p1

    refute_includes Person.not_registered_with_matching_email('FISH-registered@email.com'), p2
    assert_empty Person.not_registered_with_matching_email('fffffxxxx11z@email.com')
  end

  test 'orcid required for new person' do
    with_config_value(:orcid_required, true) do
      assert_nothing_raised do
        has_orcid = FactoryBot.create :brand_new_person, email: 'FISH-sOup1@email.com',
                                               orcid: 'http://orcid.org/0000-0002-0048-3300'
        assert has_orcid.valid?
        assert_empty has_orcid.errors[:orcid]
      end
      assert_raises ActiveRecord::RecordInvalid do
        no_orcid = FactoryBot.create :brand_new_person, email: 'FISH-sOup2@email.com'
        refute no_orcid.valid?
        assert_not_empty no_orcid.errors[:orcid]
      end
      assert_raises ActiveRecord::RecordInvalid do
        bad_orcid = FactoryBot.create :brand_new_person, email: 'FISH-sOup3@email.com',
                                               orcid: 'banana'
        refute bad_orcid.valid?
        assert_not_empty bad_orcid.errors[:orcid]
      end
    end
  end

  test 'orcid not required for existing person' do
    no_orcid = FactoryBot.create :brand_new_person, email: 'FISH-sOup1@email.com'

    with_config_value(:orcid_required, true) do
      assert_nothing_raised do
        no_orcid.update(email: 'FISH-sOup99@email.com')
        assert no_orcid.valid?
      end
    end
  end

  test 'orcid must be valid even if not required' do
    bad_orcid = FactoryBot.create :brand_new_person, email: 'FISH-sOup1@email.com'

    with_config_value(:orcid_required, true) do
      bad_orcid.update(email: 'FISH-sOup99@email.com', orcid: 'big mac')
      refute bad_orcid.valid?
      assert_not_empty bad_orcid.errors[:orcid]
    end

    with_config_value(:orcid_required, false) do
      assert_raises ActiveRecord::RecordInvalid do
        another_bad_orcid = FactoryBot.create :brand_new_person, email: 'FISH-sOup1@email.com', orcid: 'こんにちは'
        refute another_bad_orcid.valid?
        assert_not_empty bad_orcid.errors[:orcid]
      end
    end
  end

  test 'ensures full orcid uri is stored' do
    semi_orcid = FactoryBot.create :brand_new_person, email: 'FISH-sOup1@email.com',
                                            orcid: '0000-0002-0048-3300'
    full_orcid = FactoryBot.create :brand_new_person, email: 'FISH-sOup2@email.com',
                                            orcid: 'http://orcid.org/0000-0002-0048-3300'

    https_orcid = FactoryBot.create :brand_new_person, email: 'FISH-sOup3@email.com',
                                             orcid: 'https://orcid.org/0000-0002-0048-3300'

    assert_equal 'https://orcid.org/0000-0002-0048-3300', semi_orcid.orcid
    assert_equal 'https://orcid.org/0000-0002-0048-3300', full_orcid.orcid
    assert_equal 'https://orcid.org/0000-0002-0048-3300', https_orcid.orcid
  end

  test 'can flag has having left a project' do
    person = FactoryBot.create(:person)
    project = person.projects.first

    assert_not_includes person.former_projects, project
    assert_includes person.current_projects, project
    assert_includes person.projects, project

    gm = person.group_memberships.first
    gm.time_left_at = 1.day.ago
    gm.save
    assert gm.has_left
    person.reload

    assert_includes person.former_projects, project
    assert_not_includes person.current_projects, project
    assert_includes person.projects, project
  end

  test 'can flag has leaving a project' do
    person = FactoryBot.create(:person)
    project = person.projects.first

    assert_not_includes person.former_projects, project
    assert_includes person.current_projects, project
    assert_includes person.projects, project

    gm = person.group_memberships.first
    gm.time_left_at = 1.day.from_now
    gm.save
    refute gm.has_left
    person.reload

    assert_not_includes person.former_projects, project
    assert_includes person.current_projects, project
    assert_includes person.projects, project
  end

  test 'can unflag as left project' do
    person = FactoryBot.create(:person)
    project = person.projects.first

    assert_not_includes person.former_projects, project
    assert_includes person.current_projects, project
    assert_includes person.projects, project

    gm = person.group_memberships.first
    gm.time_left_at = 1.day.ago
    assert gm.save
    gm.update_column(:has_left, true)
    gm.reload
    assert gm.has_left?
    assert gm[:has_left]

    gm.time_left_at = nil
    assert gm.save
    gm.reload
    refute gm.has_left?
    refute gm[:has_left]
  end

  test 'trim spaces from email, first_name, last_name' do
    person = FactoryBot.create(:brand_new_person)
    person.email = ' fish@email.com '
    person.first_name = ' bob '
    person.last_name = ' monkhouse '
    person.web_page = ' http://fish.com '
    assert person.valid?
    disable_authorization_checks do
      person.save!
    end
    person.reload
    assert_equal 'fish@email.com', person.email
    assert_equal 'bob', person.first_name
    assert_equal 'monkhouse', person.last_name
    assert_equal 'http://fish.com', person.web_page
  end

  test 'obfuscated_email' do
    p = FactoryBot.create(:person, email: 'hello@world.org')
    assert_equal '....@world.org',p.obfuscated_email

    p = FactoryBot.create(:person, email: 'hello.every-body@world.org')
    assert_equal '....@world.org',p.obfuscated_email
  end

  test 'typeahead_hint' do
    p = FactoryBot.create(:brand_new_person,email: 'fish@world.com')
    assert p.projects.empty?
    assert_equal '....@world.com',p.typeahead_hint

    p = FactoryBot.create(:person, project:FactoryBot.create(:project,title:'wibble'))
    p.save!
    assert_equal 'wibble',p.typeahead_hint

    p.add_to_project_and_institution(FactoryBot.create(:project,title:'wobble'),p.institutions.first)
    p.save!
    p.reload
    assert_equal 'wibble, wobble',p.typeahead_hint
  end

  test 'publication authors updated with name when person deleted' do
    person = FactoryBot.create(:person, first_name: "Zak", last_name: "Bloggs")
    pub1 = FactoryBot.create(:publication, publication_authors:[FactoryBot.create(:publication_author, person:person, last_name:nil, first_name:nil)])
    pub2 = FactoryBot.create(:publication, publication_authors:[FactoryBot.create(:publication_author)])
    pub3 = FactoryBot.create(:publication, publication_authors:[FactoryBot.create(:publication_author,person:person),FactoryBot.create(:publication_author,person:FactoryBot.create(:person))])

    assert_equal 1,pub1.publication_authors.count
    assert_equal 1,pub2.publication_authors.count
    assert_equal 2,pub3.publication_authors.count

    assert_nil pub1.publication_authors.first.first_name
    assert_nil pub1.publication_authors.first.last_name
    refute_nil pub1.publication_authors.first.person

    refute_nil pub2.publication_authors.first.first_name
    refute_nil pub2.publication_authors.first.last_name
    assert_nil pub2.publication_authors.first.person

    refute_nil pub3.publication_authors.sort_by(&:first_name)[0].first_name
    refute_nil pub3.publication_authors.sort_by(&:first_name)[0].last_name
    refute_equal "Zak",pub3.publication_authors.sort_by(&:first_name)[0].first_name
    refute_equal "Bloggs",pub3.publication_authors.sort_by(&:first_name)[0].last_name
    refute_nil pub3.publication_authors.sort_by(&:first_name)[0].person

    refute_nil pub3.publication_authors.sort_by(&:first_name)[1].first_name
    refute_nil pub3.publication_authors.sort_by(&:first_name)[1].last_name
    refute_equal "Zak",pub3.publication_authors.sort_by(&:first_name)[1].first_name
    refute_equal "Bloggs",pub3.publication_authors.sort_by(&:first_name)[1].last_name
    refute_nil pub3.publication_authors.sort_by(&:first_name)[1].person

    disable_authorization_checks{person.destroy}

    pub1.reload
    pub2.reload
    pub3.reload

    assert_equal 1,pub1.publication_authors.count
    assert_equal 1,pub2.publication_authors.count
    assert_equal 2,pub3.publication_authors.count

    refute_nil pub1.publication_authors.first.first_name
    refute_nil pub1.publication_authors.first.last_name
    assert_nil pub1.publication_authors.first.person
    assert_equal "Zak",pub1.publication_authors.first.first_name
    assert_equal "Bloggs",pub1.publication_authors.first.last_name

    #unaffected
    refute_nil pub2.publication_authors.first.first_name
    refute_nil pub2.publication_authors.first.last_name
    assert_nil pub2.publication_authors.first.person


    #only one person affected, the last after sorting
    refute_nil pub3.publication_authors[1].first_name
    refute_nil pub3.publication_authors[1].last_name
    assert_equal "Zak",pub3.publication_authors.sort_by(&:first_name)[1].first_name
    assert_equal "Bloggs",pub3.publication_authors.sort_by(&:first_name)[1].last_name
    assert_nil pub3.publication_authors.sort_by(&:first_name)[1].person

    refute_nil pub3.publication_authors[0].first_name
    refute_nil pub3.publication_authors[0].last_name
    refute_equal "Zak",pub3.publication_authors.sort_by(&:first_name)[0].first_name
    refute_equal "Bloggs",pub3.publication_authors.sort_by(&:first_name)[0].last_name
    refute_nil pub3.publication_authors.sort_by(&:first_name)[0].person

  end

  test 'deleted contributor updated when person deleted' do
    data_file = FactoryBot.create(:data_file)
    person = data_file.contributor
    person_id = person.id
    things = [data_file]
    things << FactoryBot.create(:model, contributor:person)
    things << FactoryBot.create(:sop, contributor:person)
    things << FactoryBot.create(:presentation, contributor:person)
    things << FactoryBot.create(:investigation, contributor:person)
    things << FactoryBot.create(:study, contributor:person)
    things << FactoryBot.create(:assay, contributor:person)
    things << FactoryBot.create(:sample, contributor:person)
    things << FactoryBot.create(:strain, contributor:person)
    things << FactoryBot.create(:publication, contributor:person)
    things << FactoryBot.create(:simple_sample_type, contributor:person)



    things.each do |thing|
      assert_nil thing.deleted_contributor
      assert_equal person,thing.contributor
      if thing.respond_to?(:versions)
        v = thing.versions.last
        assert_nil v.deleted_contributor
        assert_equal person,v.contributor
      end
    end

    User.with_current_user(FactoryBot.create(:admin).user) do
      assert_difference('Person.count',-1) do
        assert_difference('User.count',-1) do
          person.destroy
        end
      end
    end

    things.each do |thing|
      thing.reload
      assert_nil thing.contributor, "#{thing.class.name} contributor should be nil"
      refute_nil thing.deleted_contributor, "#{thing.class.name} deleted_contributor shouldn't be nil"
      assert_equal "Person:#{person_id}",thing.deleted_contributor
      if thing.respond_to?(:versions)
        v = thing.versions.last
        assert_nil v.contributor, "#{v.class.name} contributor should be nil"
        refute_nil v.deleted_contributor, "#{v.class.name} deleted_contributor shouldn't be nil"
      end
    end
  end

  test 'administered projects' do
    person = FactoryBot.create(:project_administrator)
    project = person.projects.first

    assert_equal [project],person.administered_projects

    project2 = FactoryBot.create(:project)
    person.add_to_project_and_institution(project2,FactoryBot.create(:institution))
    disable_authorization_checks { person.is_project_administrator = true, project2 }
    assert person.is_project_administrator?(project2)
    project3 = FactoryBot.create(:project)
    person.add_to_project_and_institution(project3,FactoryBot.create(:institution))

    disable_authorization_checks { person.save! }
    person.reload

    assert_equal [project, project2, project3], person.projects.sort_by(&:id)
    assert_equal [project,project2], person.administered_projects.sort_by(&:id)
  end
end
