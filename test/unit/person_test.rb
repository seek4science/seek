require 'test_helper'

class PersonTest < ActiveSupport::TestCase
  fixtures :users, :people
  
  # Replace this with your real tests.
  def test_work_groups
    p=people(:quentin_person)
    assert_equal 2,p.work_groups.size
  end

  def test_can_be_edited_by?
    Person.all.each do |p|
      assert p.can_be_edited_by? p.user if p.user
      assert p.can_be_edited_by? users(:quentin) if (!p.is_admin? && p.user != users(:quentin))
      assert p.can_be_edited_by? users(:project_manager) if (!p.is_admin? && p.user != users(:quentin) && !(p.projects & users(:project_manager).person.projects).empty?)
      assert !p.can_be_edited_by?(users(:can_edit)) unless (p.user == users(:can_edit))
    end
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
    sorted = Person.find(:all).sort_by do |p|
      lname = "" || p.last_name.try(:downcase)
      fname = "" || p.first_name.try(:downcase)
      lname+fname
    end
    assert_equal sorted, Person.find(:all)
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
  
  def test_without_group
    without_group=Person.without_group
    without_group.each do |p|
      assert_equal 0,p.group_memberships.size
    end
    assert !without_group.include?(people(:quentin_person))
    assert without_group.include?(people(:person_without_group))
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
    p=people(:quentin_person)
    assert_equal 2,p.institutions.size
    
    p=people(:aaron_person)
    assert_equal 2,p.work_groups.size
    assert_equal 2,p.projects.size
    assert_equal 1,p.institutions.size
  end
  
  def test_projects
    p=people(:quentin_person)
    assert_equal 2,p.projects.size
  end
  
  def test_userless_people
    peeps=Person.userless_people
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
  
  def test_roles_association
    role = Factory(:project_role)
    p=Factory :person
    p.group_memberships.first.project_roles << role
    assert_equal 1, p.project_roles.size
    assert p.project_roles.include?(role)
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
    assert true,p.receive_notifications?    
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
  
  test 'assign admin role for a person' do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person)
      assert_equal [], person.roles
      assert person.can_manage?
      person.roles=['admin']
      person.save!
      person.reload
      assert_equal ['admin'], person.roles
    end
  end

  test 'add roles for a person' do
    User.with_current_user Factory(:admin).user do
      person = Factory(:admin)
      assert_equal ['admin'], person.roles
      assert person.can_manage?
      person.add_roles ['admin', 'pal']
      person.save!
      person.reload
      assert_equal ['admin', 'pal'].sort, person.roles.sort
    end
  end

  test 'remove roles for a person' do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person)
      person.roles = ['admin', 'pal']
      person.remove_roles ['admin']
      person.save!
      person.reload
      assert_equal ['pal'], person.roles
    end
  end

  test 'non-admin can not change the roles of a person' do
    person = Factory(:person)
    User.with_current_user person.user do

      person.roles = ['admin', 'pal']
      assert person.can_edit?
      assert !person.save
      assert !person.errors.empty?
      person.reload
      assert_equal [], person.roles
    end
  end

  test 'is_admin?' do
     User.with_current_user Factory(:admin).user do
      person = Factory(:person)
      person.is_admin = true
      person.save!

      assert person.is_admin?

      person.is_admin = false
      person.save!

      assert !person.is_admin?
    end
  end

  test 'is_pal?' do
     User.with_current_user Factory(:admin).user do
      person = Factory(:person)
      person.is_pal = true
      person.save!

      assert person.is_pal?

      person.is_pal = false
      person.save!

      assert !person.is_pal?
    end
  end

  test 'is_project_manager?' do
     User.with_current_user Factory(:admin).user do
      person = Factory(:person)
      person.is_project_manager= true
      person.save!

      assert person.is_project_manager?

      person.is_project_manager=false
      person.save!

      assert !person.is_project_manager?
    end
  end

  test 'is_gatekeeper?' do
     User.with_current_user Factory(:admin).user do
      person = Factory(:person)
      person.is_gatekeeper= true
      person.save!

      assert person.is_gatekeeper?

      person.is_gatekeeper=false
      person.save!

      assert !person.is_gatekeeper?
    end
  end

  test 'is_asset_manager?' do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person)
      person.is_asset_manager = true
      person.save!

      assert person.is_asset_manager?

      person.is_asset_manager=false
      person.save!

      assert !person.is_asset_manager?
    end
  end

  test 'is_asset_manager_of?' do
    asset_manager = Factory(:asset_manager)
    sop = Factory(:sop)
    assert !asset_manager.is_asset_manager_of?(sop)

    disable_authorization_checks{sop.projects = asset_manager.projects}
    assert asset_manager.is_asset_manager_of?(sop)
  end

  test 'is_gatekeeper_of?' do
    gatekeeper = Factory(:gatekeeper)
    sop = Factory(:sop)
    assert !gatekeeper.is_gatekeeper_of?(sop)

    disable_authorization_checks{sop.projects = gatekeeper.projects}
    assert gatekeeper.is_gatekeeper_of?(sop)
  end

  test 'replace admins, pals named_scope by a static function' do
    admins = Person.admins
    assert_equal 1, admins.count
    assert admins.include?(people(:quentin_person))

    pals = Person.pals
    assert_equal 1, pals.count
    assert pals.include?(people(:pal))
  end

  test "can_create_new_items" do
    p=Factory :person
    assert p.can_create_new_items?
    assert p.member?

    p.group_memberships.destroy_all

    #this is necessary because Person caches the projects in the instance variable @known_projects
    p = Person.find(p.id)
    assert !p.member?
    assert !p.can_create_new_items?

  end

end
