require 'test_helper'

class PersonTest < ActiveSupport::TestCase
  fixtures :users, :people
  
  # Replace this with your real tests.
  def test_work_groups
    p=Factory(:person_in_multiple_projects)
    assert_equal 3,p.work_groups.size
  end

  test "registered user's profile can be edited by" do
    admin = Factory(:admin)
    project_administrator = Factory(:project_administrator)
    project_administrator2 = Factory(:project_administrator)
    person = Factory :person,:group_memberships=>[Factory(:group_membership,:work_group=>project_administrator.group_memberships.first.work_group)]
    another_person = Factory :person

    assert_equal person.projects,project_administrator.projects
    assert_not_equal person.projects,project_administrator2.projects

    assert person.can_be_edited_by?(person.user)
    assert !person.can_be_edited_by?(project_administrator.user),"should not be editable by the project administrator of the same project, as user is registered"
    assert person.can_be_edited_by?(admin.user)
    assert !person.can_be_edited_by?(another_person.user)
    assert !person.can_be_edited_by?(project_administrator2.user),"should be not editable by the project administrator of another project"

    assert person.can_be_edited_by?(person), "You can also ask by passing in a person"
    assert !person.can_be_edited_by?(project_administrator),"You can also ask by passing in a person"
  end

  test "userless profile can be edited by" do
    admin = Factory(:admin)
    project_administrator = Factory(:project_administrator)
    project_administrator2 = Factory(:project_administrator)
    profile = Factory :brand_new_person,:group_memberships=>[Factory(:group_membership,:work_group=>project_administrator.group_memberships.first.work_group)]
    another_person = Factory :person

    assert_equal profile.projects,project_administrator.projects
    assert_not_equal profile.projects,project_administrator2.projects

    assert profile.can_be_edited_by?(project_administrator.user),"should be editable by the project administrator of the same project, as user is not registered"
    assert profile.can_be_edited_by?(admin.user)
    assert !profile.can_be_edited_by?(another_person.user)
    assert !profile.can_be_edited_by?(project_administrator2.user),"should be not editable by the project administrator of another project"

    assert profile.can_be_edited_by?(project_administrator),"You can also ask by passing in a person"
  end

  test "me?" do
    person = Factory(:person)
    refute person.me?
    User.current_user = person.user
    assert person.me?
    person = Factory(:brand_new_person)
    assert_nil person.user
    refute person.me?
    User.current_user = nil
    refute person.me?
  end

  test "programmes" do
    person1=Factory(:person)
    prog = Factory(:programme,:projects=>person1.projects)
    prog2 = Factory(:programme)
    assert_includes person1.programmes,prog
    refute_includes person1.programmes,prog2
  end

  test "can be administered by" do
    admin = Factory(:admin)
    admin2 = Factory(:admin)
    project_administrator = Factory(:project_administrator)
    person_in_same_project = Factory :person,:group_memberships=>[Factory(:group_membership,:work_group=>project_administrator.group_memberships.first.work_group)]
    person_in_different_project = Factory :person

    assert admin.can_be_administered_by?(admin.user),"admin can administer themself"
    assert admin2.can_be_administered_by?(admin.user),"admin can administer another admin"

    assert project_administrator.can_be_administered_by?(admin.user),"admin should be able to administer another project administrator"
    assert person_in_same_project.can_be_administered_by?(project_administrator.user),"project administrator should be able to administer someone from same project"
    assert person_in_different_project.can_be_administered_by?(project_administrator.user),"project administrator should be able to administer someone from another project"

    assert !project_administrator.can_be_administered_by?(person_in_same_project.user),"a normal person cannot administer someone else"
    assert !project_administrator.can_be_administered_by?(project_administrator.user),"project administrator should not administer himself"
    assert !person_in_same_project.can_be_administered_by?(person_in_same_project.user), "person should not administer themself"
    assert !person_in_same_project.can_be_administered_by?(nil)

    assert project_administrator.can_be_administered_by?(admin),"you can also ask by passing a person"
    assert person_in_same_project.can_be_administered_by?(project_administrator),"you can also ask by passing a person"

    #can be administered by a programme administrator
    pa = Factory :programme_administrator
    assert Factory(:person).can_be_administered_by?(pa.user)


  end

  test "project administrator cannot edit an admin within their project" do
    admin = Factory(:admin)
    project_administrator = Factory(:project_administrator,:group_memberships=>[Factory(:group_membership,:work_group=>admin.group_memberships.first.work_group)])


    assert !(admin.projects & project_administrator.projects).empty?

    assert !admin.can_be_edited_by?(project_administrator)
  end

  #checks the updated_at doesn't get artificially changed between created and reloading
  def test_updated_at
    person = Factory(:person, :updated_at=>1.week.ago)

    updated_at = person.updated_at
    person = Person.find(person.id)
    assert_equal updated_at.to_s,person.updated_at.to_s
  end

  test "to_rdf" do
    object = Factory :person, :skype_name=>"skypee",:email=>"sdkfhsd22fkhfsd@sdkfsdkhfkhsdf.com"
    Factory(:study,:contributor=>object)
    Factory(:investigation,:contributor=>object)
    Factory(:assay,:contributor=>object)
    Factory(:assay,:contributor=>object)
    Factory(:assets_creator,:creator=>object)
    Factory(:assets_creator,:asset=>Factory(:sop),:creator=>object)
    object.web_page="http://google.com"

    disable_authorization_checks do
      object.save!
    end
    object.reload
    rdf = object.to_rdf

    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count > 1
      assert_equal RDF::URI.new("http://localhost:3000/people/#{object.id}"), reader.statements.first.subject
      assert reader.has_triple? ["http://localhost:3000/people/#{object.id}",RDF::FOAF.mbox_sha1sum,"b507549e01d249ee5ed98bd40e4d86d1470a13b8"]
    end
  end

  test "orcid id validation" do
    p = Factory :person
    p.orcid = nil
    assert p.valid?
    p.orcid = "sdff-1111-1111-1111"
    assert !p.valid?
    p.orcid = "1111111111111111"
    assert !p.valid?
    p.orcid = "0000-0002-1694-2339"
    assert !p.valid?,"checksum doesn't match"
    p.orcid = "0000-0002-1694-233X"
    assert p.valid?
    p.orcid = "http://orcid.org/0000-0002-1694-233X"
    assert p.valid?
    p.orcid = "http://orcid.org/0000-0003-2130-0865"
    assert p.valid?
  end

  test "orcid_uri" do
    disable_authorization_checks do
      p = Factory :person
      p.orcid = "http://orcid.org/0000-0003-2130-0865"
      assert p.valid?
      p.save!
      p.reload
      assert_equal "http://orcid.org/0000-0003-2130-0865",p.orcid_uri

      p.orcid = "0000-0002-1694-233X"
      p.save!
      p.reload
      assert_equal "http://orcid.org/0000-0002-1694-233X",p.orcid_uri

      p.orcid=nil
      p.save!
      p.reload
      assert_nil p.orcid_uri

      p.orcid=""
      p.save!
      p.reload
      assert_nil p.orcid_uri
    end


  end


  test "email uri" do
    p = Factory :person, :email=>"sfkh^sd@weoruweoru.com"
    assert_equal "mailto:sfkh%5Esd@weoruweoru.com",p.email_uri
  end


  test "only first admin person" do
    Person.delete_all
    person = Factory :admin
    assert person.only_first_admin_person?

    person.is_admin=false
    disable_authorization_checks{person.save!}
    assert !person.only_first_admin_person?
    person.is_admin=true
    disable_authorization_checks{person.save!}
    assert person.only_first_admin_person?
    Factory :person
    assert !person.only_first_admin_person?

  end

  def test_active_ordered_by_updated_at_and_avatar_not_null

    Person.delete_all

    avatar = Factory :avatar

    people = []

    people << Factory(:person,:avatar=>avatar, :updated_at=>1.week.ago)
    people << Factory(:person,:avatar=>avatar, :updated_at=>1.minute.ago)
    people << Factory(:person,:updated_at=>1.day.ago)
    people << Factory(:person,:updated_at=>1.hour.ago)
    people << Factory(:person,:updated_at=>2.minutes.ago)

    sorted = Person.all.sort do |x,y|
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

  def test_ordered_by_last_name
    sorted = Person.all.sort_by do |p|
      lname = "" || p.last_name.try(:downcase)
      fname = "" || p.first_name.try(:downcase)
      lname+fname
    end
    assert_equal sorted, Person.all
  end

  def test_is_asset
    assert !Person.is_asset?
    assert !people(:quentin_person).is_asset?
    assert !people(:quentin_person).is_downloadable_asset?
  end

  def test_member_of
    p=Factory :person
    proj = Factory :project
    assert !p.projects.empty?
    assert p.member_of?(p.projects.first)
    assert !p.member_of?(proj)
  end

  def test_avatar_key
    p=people(:quentin_person)
    assert_nil p.avatar_key
    assert p.defines_own_avatar?
  end

  def test_first_person_is_admin
    assert Person.count>0 #should already be people from fixtures
    p=Person.new(:first_name=>"XXX",:email=>"xxx@email.com")
    p.save!
    assert !p.is_admin?, "Should not automatically be admin, since people already exist"

    Person.delete_all

    assert_equal 0,Person.count #no people should exist
    p=Person.new(:first_name=>"XXX",:email=>"xxx@email.com")
    p.save
    p.reload
    assert p.is_admin?, "Should automatically be admin, since it is the first created person"
  end

  test "first person in default project" do
    Factory(:person) #make sure there is a person, project and institution registered

    assert Person.count>0
    assert Project.count>0
    p=Person.new(:first_name=>"XXX",:email=>"xxx@email.com")
    p.save!
    assert !p.is_admin?, "Should not automatically be admin, since people already exist"
    assert_empty p.projects
    assert_empty p.institutions

    Person.delete_all

    project = Project.first
    institution = project.institutions.first
    refute_nil project
    refute_nil institution

    assert_equal 0,Person.count #no people should exist
    p=Person.new(:first_name=>"XXX",:email=>"xxx@email.com")
    p.save!
    p.reload
    assert_equal [project],p.projects
    assert_equal [institution],p.institutions
  end

  
  def test_registered
    registered=Person.registered
    registered.each do |p|
      assert_not_nil p.user
    end
    assert registered.include?(people(:quentin_person))
    assert !registered.include?(people(:person_without_user))
  end
  
  def test_duplicates
    dups=Person.duplicates
    assert !dups.empty?
    assert dups.include?(people(:duplicate_1))
    assert dups.include?(people(:duplicate_2))
  end
  
  test "without group" do
    no_group = Factory(:brand_new_person)
    in_group = Factory(:person)
    assert no_group.projects.empty?
    assert !in_group.projects.empty?
    all = Person.without_group
    assert !all.include?(in_group)
    assert all.include?(no_group)
  end

  test "with group" do
    no_group = Factory(:brand_new_person)
    in_group = Factory(:person)
    assert no_group.projects.empty?
    assert !in_group.projects.empty?
    all = Person.with_group
    assert all.include?(in_group)
    assert !all.include?(no_group)
  end
  
  def test_expertise
    p=Factory :person
    Factory :expertise,:value=>"golf",:annotatable=>p
    Factory :expertise,:value=>"fishing",:annotatable=>p
    Factory :tool,:value=>"sbml",:annotatable=>p

    assert_equal 2, p.expertise.size
    
    p=Factory :person
    Factory :expertise,:value=>"golf",:annotatable=>p
    Factory :tool,:value=>"sbml",:annotatable=>p
    assert_equal 1, p.expertise.size
    assert_equal "golf",p.expertise[0].text
  end

  def test_tools
    p=Factory :person
    Factory :tool,:value=>"sbml",:annotatable=>p
    Factory :tool,:value=>"java",:annotatable=>p
    Factory :expertise,:value=>"sbml",:annotatable=>p

    assert_equal 2, p.tools.size

    p=Factory :person
    Factory :tool,:value=>"sbml",:annotatable=>p
    Factory :expertise,:value=>"fishing",:annotatable=>p
    assert_equal 1, p.tools.size
    assert_equal "sbml",p.tools[0].text
  end

  def test_assign_expertise
    p=Factory :person
    User.with_current_user p.user do
      assert_equal 0,p.expertise.size
      assert_difference("Annotation.count",2) do
        assert_difference("TextValue.count",2) do
          p.expertise = ["golf","fishing"]
        end
      end

      assert_equal 2,p.expertise.size
      assert p.expertise.collect{|e| e.text}.include?("golf")
      assert p.expertise.collect{|e| e.text}.include?("fishing")

      assert_difference("Annotation.count",-1) do
        assert_no_difference("TextValue.count") do
          p.expertise = ["golf"]
        end
      end

      assert_equal 1,p.expertise.size
      assert_equal "golf",p.expertise[0].text

      p2=Factory :person
      assert_difference("Annotation.count") do
        assert_no_difference("TextValue.count") do
          p2.expertise = ["golf"]
        end
      end
    end
  end

  def test_assigns_tools
    p=Factory :person
    User.with_current_user p.user do
      assert_equal 0,p.tools.size
      assert_difference("Annotation.count",2) do
        assert_difference("TextValue.count",2) do
          p.tools = ["golf","fishing"]
        end
      end

      assert_equal 2,p.tools.size
      assert p.tools.collect{|e| e.text}.include?("golf")
      assert p.tools.collect{|e| e.text}.include?("fishing")

      assert_difference("Annotation.count",-1) do
        assert_no_difference("TextValue.count") do
          p.tools = ["golf"]
        end
      end

      assert_equal 1,p.tools.size
      assert_equal "golf",p.tools[0].text

      p2=Factory :person
      assert_difference("Annotation.count") do
        assert_no_difference("TextValue.count") do
          p2.tools = ["golf"]
        end
      end
    end

  end

  def test_removes_previously_assigned
    p=Factory :person
    User.with_current_user p.user do
      p.tools = ["one","two"]
      assert_equal 2,p.tools.size
      p.tools = ["three"]
      assert_equal 1,p.tools.size
      assert_equal "three",p.tools[0].text

      p=Factory :person
      p.expertise = ["aaa","bbb"]
      assert_equal 2,p.expertise.size
      p.expertise = ["ccc"]
      assert_equal 1,p.expertise.size
      assert_equal "ccc",p.expertise[0].text
    end

  end

  def test_expertise_and_tools_with_same_name
    p=Factory :person
    User.with_current_user p.user do
      assert_difference("Annotation.count",2) do
        assert_difference("TextValue.count",2) do
          p.tools = ["golf","fishing"]
        end
      end

      assert_difference("Annotation.count",2) do
        assert_no_difference("TextValue.count") do
          p.expertise = ["golf","fishing"]
        end
      end
    end
  end
  
  def test_institutions
    person = Factory(:person_in_multiple_projects)

    institution = person.group_memberships.first.work_group.institution
    institution2 = Factory(:institution)

    assert_equal 3,person.institutions.count
    assert person.institutions.include?(institution)
    assert !person.institutions.include?(institution2)
  end
  
  def test_projects
    p=Factory(:person_in_multiple_projects)
    assert_equal 3,p.projects.size
  end
  
  test "not registered" do
    peeps=Person.not_registered
    assert_not_nil peeps
    assert peeps.size>0,"There should be some userless people"
    assert_nil(peeps.find{|p| !p.user.nil?},"There should be no people with a non nil user")
    
    p=people(:three)
    assert_not_nil(peeps.find{|person| p.id==person.id},"Person :three should be userless and therefore in the list")
    
    p=people(:quentin_person)
    assert_nil(peeps.find{|person| p.id==person.id},"Person :one should have a user and not be in the list")
  end
  
  def test_name
    p=people(:quentin_person)
    assert_equal "Quentin Jones", p.name
    p.first_name="Tom"
    assert_equal "Tom Jones", p.name
  end
  
  def test_email_with_name
    p=people(:quentin_person)
    assert_equal("Quentin Jones <quentin@email.com>",p.email_with_name)
  end
  
  def test_email_with_name_no_last_name
    p=Person.new(:first_name=>"Fred",:email=>"fff@fff.com")
    assert_equal("Fred <fff@fff.com>",p.email_with_name)
  end
  
  def test_capitalization_with_nil_last_name
    p=people(:no_first_name)
    assert_equal "Lastname",p.name
  end
  
  def test_capitalization_with_nil_first_name
    p=people(:no_last_name)
    assert_equal "Firstname",p.name
  end
  
  def test_double_firstname_capitalised
    p=people(:double_firstname)
    assert_equal "Fred David Bloggs", p.name
  end
  
  def test_double_lastname_capitalised
    p=people(:double_lastname)
    assert_equal "Fred Smith Jones",p.name
  end
  
  def test_double_barrelled_lastname_capitalised
    p=people(:double_barrelled_lastname)
    assert_equal "Fred Smith-Jones",p.name
  end
  
  def test_valid
    p=people(:quentin_person)
    assert p.valid?
    p.email=nil
    assert !p.valid?
    
    p.email="sdf"
    assert !p.valid?
    
    p.email="sdf@"
    assert !p.valid?    
    
    p.email="sdaf@sdf.com"
    assert p.valid?
    
    p.web_page=nil
    assert p.valid?
    
    p.web_page=""
    assert p.valid?
    
    p.web_page="sdfsdf"
    assert !p.valid?
    
    p.web_page="http://google.com"
    assert p.valid?
    
    p.web_page="https://google.com"
    assert p.valid?
    
    p.web_page="http://google.com/fred"
    assert p.valid?
    
    p.web_page="http://google.com/fred?param=bob"
    assert p.valid?
    
    p.web_page="http://www.mygrid.org.uk/dev/issues/secure/IssueNavigator.jspa?reset=true&mode=hide&sorter/order=DESC&sorter/field=priority&resolution=-1&pid=10051&fixfor=10110"
    assert p.valid?
    
  end
  
  def test_email_with_capitalise_valid
    p=people(:quentin_person)
    assert p.valid?
    p.email="gordon.brown@gov.uk"
    assert p.valid?
    p.email="Gordon.Brown@gov.uk"
    assert p.valid?,"Capitals in email should be valid"
  end
  
  def test_email_unique
    p=people(:quentin_person)
    newP=Person.new(:first_name=>"Fred",:email=>p.email)
    assert !newP.valid?,"Should not be valid as email is not unique"
    newP.email = p.email.capitalize
    assert !newP.valid?,"Should not be valid as email is not case sensitive"
    newP.email="zxczxc@zxczxczxc.com"
    assert newP.valid?
  end
  
  def test_disciplines
    p = Factory :person,:disciplines=>[Factory(:discipline,:title=>"A"),Factory(:discipline, :title=>"B")]
    p.reload
    assert_equal 2,p.disciplines.size
    assert_equal "A",p.disciplines[0].title
    assert_equal "B",p.disciplines[1].title

  end
  
  def test_positions_association
    position = Factory(:project_position)
    p=Factory :person
    p.group_memberships.first.project_positions << position
    assert_equal 1, p.project_positions.size
    assert p.project_positions.include?(position)
  end
  
  def test_update_first_letter
    p=Person.new(:first_name=>"Fred",:last_name=>"Monkhouse",:email=>"blahblah@email.com")
    assert p.valid?,"The new person should be valid"
    p.save
    assert_equal "M",p.first_letter
    
    p=Person.new(:first_name=>"Freddy",:email=>"blahbddlah@email.com")
    assert p.valid?,"The new person should be valid"
    p.save
    assert_equal "F",p.first_letter
    
    p=Person.new(:first_name=>"Zebedee",:email=>"zz@email.com")
    assert p.valid?,"The new person should be valid"
    p.save
    assert_equal "Z",p.first_letter
  end
  
  def test_update_first_letter_blank_last_name
    p=Person.new(:first_name=>"Zebedee",:last_name=>"",:email=>"zz@email.com")
    assert p.valid?,"The new person should be valid"
    p.save
    assert_equal "Z",p.first_letter    
  end
  
  def test_notifiee_info_inserted
    p=Person.new(:first_name=>"Zebedee",:last_name=>"",:email=>"zz@email.com")
    assert_nil p.notifiee_info
    assert_difference("NotifieeInfo.count") do
      p.save!
    end
    p=Person.find(p.id)
    assert_not_nil p.notifiee_info
    assert p.receive_notifications?
  end
  
  def test_dependent_notifiee_info_is_destroyed_with_person
    p=Person.new(:first_name=>"Zebedee",:last_name=>"",:email=>"zz@email.com")
    p.save!
    assert_not_nil p.notifiee_info
    assert_difference("NotifieeInfo.count",-1) do
      p.destroy
    end    
  end
  
  def test_user_is_destroyed_with_person
    p=people(:quentin_person)
    u=users(:quentin)
    assert_difference("Person.count",-1) do
      assert_difference("User.count",-1) do
        p.destroy
      end
    end
    assert_nil User.find_by_id(u.id)
    
    p=people(:random_userless_person)
    assert_difference("Person.count",-1) do
      assert_no_difference("User.count") do
        p.destroy
      end
    end
  end
  
  def test_updated_not_changed_when_adding_notifiee_info
    p=people(:modeller_person)
    up_at=p.updated_at
    sleep(2)
    p.check_for_notifiee_info
    assert_equal up_at,p.updated_at
  end
  
  test "test uuid generated" do
    p = people(:modeller_person)
    assert_nil p.attributes["uuid"]
    p.save
    assert_not_nil p.attributes["uuid"]
  end  
  
  test "uuid doesn't change" do
    x = people(:modeller_person)
    x.save
    uuid = x.attributes["uuid"]
    x.save
    assert_equal x.uuid, uuid
  end

  test 'projects method notices changes via both group_memberships and work_groups' do
    person = Factory.build(:person, :group_memberships => [Factory(:group_membership)])
    group_membership_projects = person.group_memberships.map(&:work_group).map(&:project).uniq.sort_by(&:title)
    work_group_projects = person.work_groups.map(&:project).uniq.sort_by(&:title)
    assert_equal (group_membership_projects | work_group_projects), person.projects.sort_by(&:title)
  end

  test 'should retrieve the list of people who have the manage right on the item' do
    user = Factory(:user)
    person = user.person
    data_file = Factory(:data_file, :contributor => user)
    people_can_manage = data_file.people_can_manage
    assert_equal 1, people_can_manage.count
    assert_equal person.id, people_can_manage.first[0]

    new_person = Factory(:person_in_project)
    policy = data_file.policy
    policy.permissions.build(:contributor => new_person, :access_type => Policy::MANAGING)
    policy.save
    people_can_manage = data_file.people_can_manage
    assert_equal 2, people_can_manage.count
    people_ids = people_can_manage.collect{|p| p[0]}
    assert people_ids.include? person.id
    assert people_ids.include? new_person.id
  end

  test "related resource" do
    user = Factory :user
    person = user.person
    User.with_current_user(user) do
      AssetsCreator.create :asset=>Factory(:data_file),:creator=> person
      AssetsCreator.create :asset=>Factory(:model),:creator=> person
      AssetsCreator.create :asset=>Factory(:sop),:creator=> person
      Factory :event,:contributor=>user
      AssetsCreator.create :asset=>Factory(:presentation),:creator=> person
      AssetsCreator.create :asset=>Factory(:publication),:creator=>person
      assert_equal person.created_data_files, person.related_data_files
      assert_equal person.created_models, person.related_models
      assert_equal person.created_sops,  person.related_sops
      assert_equal user.events, person.related_events
      assert_equal person.created_presentations, person.related_presentations
      assert_equal person.created_publications, person.related_publications
    end
  end


  test "get the correct investigations and studides" do
    p = Factory(:person)
    u = p.user

    inv1 = Factory(:investigation, :contributor=>p)
    inv2 = Factory(:investigation, :contributor=>u)

    study1 = Factory(:study, :contributor=>p)
    study2 = Factory(:study, :contributor=>u)
    p = Person.find(p.id)

    assert_equal [study1,study2],p.studies.sort_by(&:id)

    assert_equal [inv1,inv2],p.investigations.sort_by(&:id)

  end

  test "should be able to remove the workgroup whose project is not subcribed" do
    p=Factory :person
    wg = Factory :work_group
    p.work_groups = [wg]

    p.project_subscriptions.delete_all
    assert p.project_subscriptions.empty?
    p.work_groups = []
    p.save
    assert_empty p.work_groups
    assert_empty p.projects
  end

  test "add to project and institution subscribes to project" do
    person = Factory (:brand_new_person)
    inst = Factory(:institution)
    proj = Factory(:project)

    assert_empty person.project_subscriptions
    person.add_to_project_and_institution(proj,inst)
    person.save!

    person.reload
    assert_includes person.project_subscriptions.map(&:project),proj

  end

  test "shares programme?" do
    person1 = Factory(:person)
    person2 = Factory(:person)
    person3 = Factory(:person)

    prog1 = Factory :programme,:projects=>(person1.projects | person2.projects)
    prog2 = Factory :programme,:projects=>person3.projects
    assert person1.shares_programme?(person2)
    assert person2.shares_programme?(person1)
    refute person3.shares_programme?(person1)
    refute person3.shares_programme?(person2)
    refute person1.shares_programme?(person3)
    refute person2.shares_programme?(person3)

    #also with project rather than person
    assert person1.shares_programme?(person2.projects.first)
    refute person2.shares_programme?(person3.projects.first)
  end

  test "shares project?" do
    person1 = Factory(:person)
    project = person1.projects.first
    person2 = Factory(:person,:work_groups=>[project.work_groups.first])
    person3 = Factory(:person)

    assert person1.shares_project?(person2)
    refute person1.shares_project?(person3)

    assert person1.shares_project?(project)
    refute person1.shares_project?(person3.projects.first)

    assert person1.shares_project?([project])
    assert person1.shares_project?([project,Factory(:project)])
    refute person1.shares_project?([person3.projects.first])
    refute person1.shares_project?([person3.projects.first,Factory(:project)])
  end

  test "add to project and institution" do
    proj1=Factory :project
    proj2=Factory :project

    inst1=Factory :institution
    inst2=Factory :institution

    p1=Factory :brand_new_person
    p2=Factory :brand_new_person
    assert_difference("WorkGroup.count",1) do
      assert_difference("GroupMembership.count",1) do
        p1.add_to_project_and_institution(proj1,inst1)
        p1.save!
      end
    end
    p1.reload
    assert_equal 1,p1.projects.count
    assert_include p1.projects,proj1
    assert_equal 1,p1.institutions.count
    assert_include p1.institutions,inst1

    assert_no_difference("WorkGroup.count") do
      assert_difference("GroupMembership.count",1) do
        p2.add_to_project_and_institution(proj1,inst1)
      end
    end

    p2.reload
    assert_equal 1,p2.projects.count
    assert_include p2.projects,proj1
    assert_equal 1,p2.institutions.count
    assert_include p2.institutions,inst1

    assert_difference("WorkGroup.count",1) do
      assert_difference("GroupMembership.count",1) do
        p1.add_to_project_and_institution(proj2,inst1)
      end
    end

    assert_difference("WorkGroup.count",1) do
      assert_difference("GroupMembership.count",1) do
        p1.add_to_project_and_institution(proj1,inst2)
      end
    end

    p1.reload
    assert_equal 2,p1.projects.count
    assert_include p1.projects,proj2
    assert_equal 2,p1.institutions.count
    assert_include p1.institutions,inst2

    assert_no_difference("WorkGroup.count") do
      assert_no_difference("GroupMembership.count") do
        p1.add_to_project_and_institution(proj1,inst1)
      end
    end
  end

  test "cache-key changes with workgroup" do
    person = Factory :person
    refute_empty person.projects
    cachekey = person.cache_key
    person.add_to_project_and_institution(Factory(:project),Factory(:institution))
    refute_equal cachekey,person.cache_key
  end

  test "can create" do
    User.current_user=Factory(:project_administrator).user
    assert Person.can_create?

    User.current_user=Factory(:admin).user
    assert Person.can_create?

    User.current_user=Factory(:brand_new_user)
    refute User.current_user.registration_complete?
    assert Person.can_create?

    User.current_user = nil
    refute Person.can_create?

    User.current_user=Factory(:person).user
    refute Person.can_create?

    User.current_user=Factory(:pal).user
    refute Person.can_create?

    User.current_user=Factory(:asset_gatekeeper).user
    refute Person.can_create?

    User.current_user=Factory(:asset_housekeeper).user
    refute Person.can_create?

    User.current_user=Factory(:programme_administrator).user
    assert Person.can_create?

  end

  test "administered programmes" do
    pa = Factory(:programme_administrator)
    admin = Factory(:admin)
    other_prog = Factory(:programme)
    progs = pa.programmes
    assert_equal progs.sort,pa.administered_programmes.sort
    refute_includes pa.administered_programmes,other_prog

    assert_empty Factory(:person).administered_programmes
    assert_equal Programme.all.sort,admin.administered_programmes
  end

  test "not_registered_with_matching_email" do
    3.times do
      Factory :person
    end
    p1 = Factory :brand_new_person, :email=>"FISH-sOup@email.com"
    p2 = Factory :person, :email=>"FISH-registered@email.com"

    refute p1.registered?
    assert p2.registered?

    assert_includes Person.not_registered_with_matching_email("FISH-sOup@email.com"),p1
    assert_includes Person.not_registered_with_matching_email("fish-soup@email.com"),p1

    refute_includes Person.not_registered_with_matching_email("FISH-registered@email.com"),p2
    assert_empty Person.not_registered_with_matching_email("fffffxxxx11z@email.com")
  end

  test "orcid required for new person" do
    with_config_value(:orcid_required, true) do
      assert_nothing_raised do
        has_orcid = Factory :brand_new_person, :email => "FISH-sOup1@email.com",
                            :orcid => 'http://orcid.org/0000-0002-0048-3300'
        assert has_orcid.valid?
        assert_empty has_orcid.errors[:orcid]
      end
      assert_raises ActiveRecord::RecordInvalid do
        no_orcid = Factory :brand_new_person, :email => "FISH-sOup2@email.com"
        assert !no_orcid.valid?
        assert_not_empty no_orcid.errors[:orcid]
      end
      assert_raises ActiveRecord::RecordInvalid do
        bad_orcid = Factory :brand_new_person, :email => "FISH-sOup3@email.com",
                            :orcid => 'banana'
        assert !bad_orcid.valid?
        assert_not_empty bad_orcid.errors[:orcid]
      end
    end
  end

  test "orcid not required for existing person" do
    no_orcid = Factory :brand_new_person, :email => "FISH-sOup1@email.com"

    with_config_value(:orcid_required, true) do
      assert_nothing_raised do
        no_orcid.update_attributes(:email => "FISH-sOup99@email.com")
        assert no_orcid.valid?
      end
    end
  end

  test "orcid must be valid even if not required" do
    bad_orcid = Factory :brand_new_person, :email => "FISH-sOup1@email.com"

    with_config_value(:orcid_required, true) do
      bad_orcid.update_attributes(:email => "FISH-sOup99@email.com", :orcid => 'big mac')
      assert !bad_orcid.valid?
      assert_not_empty bad_orcid.errors[:orcid]
    end

    with_config_value(:orcid_required, false) do
      assert_raises ActiveRecord::RecordInvalid do
        another_bad_orcid = Factory :brand_new_person, :email => "FISH-sOup1@email.com", :orcid => 'こんにちは'
        assert !another_bad_orcid.valid?
        assert_not_empty bad_orcid.errors[:orcid]
      end
    end
  end

  test "ensures full orcid uri is stored" do
    semi_orcid = Factory :brand_new_person, :email => "FISH-sOup1@email.com",
                         :orcid => '0000-0002-0048-3300'
    full_orcid = Factory :brand_new_person, :email => "FISH-sOup2@email.com",
                         :orcid => 'http://orcid.org/0000-0002-0048-3300'

    assert_equal 'http://orcid.org/0000-0002-0048-3300', semi_orcid.orcid
    assert_equal 'http://orcid.org/0000-0002-0048-3300', full_orcid.orcid
  end

  test "can flag has having left a project" do
    person = Factory(:person)
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

  test "can flag has leaving a project" do
    person = Factory(:person)
    project = person.projects.first

    assert_not_includes person.former_projects, project
    assert_includes person.current_projects, project
    assert_includes person.projects, project

    gm = person.group_memberships.first
    gm.time_left_at = 1.day.from_now
    gm.save
    assert !gm.has_left
    person.reload

    assert_not_includes person.former_projects, project
    assert_includes person.current_projects, project
    assert_includes person.projects, project
  end

  test 'trim spaces from email, first_name, last_name' do
    person = Factory(:brand_new_person)
    person.email = ' fish@email.com '
    person.first_name = ' bob '
    person.last_name = ' monkhouse '
    person.web_page = ' http://fish.com '
    assert person.valid?
    disable_authorization_checks do
      person.save!
    end
    person.reload
    assert_equal 'fish@email.com',person.email
    assert_equal 'bob',person.first_name
    assert_equal 'monkhouse',person.last_name
    assert_equal 'http://fish.com',person.web_page
  end

end
