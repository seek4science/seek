require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  
  fixtures :projects, :institutions, :work_groups, :group_memberships, :people, :users,  :publications, :assets, :organisms
  #checks that the dependent work_groups are destoryed when the project s
  def test_delete_work_groups_when_project_deleted
    n_wg=WorkGroup.all.size
    p=Project.find(2)
    assert_equal 1,p.work_groups.size
    wg = p.work_groups.first
        
    wg.people=[]
    wg.save!
    User.current_user = Factory(:admin).user
    p.destroy
    
    assert_equal nil,WorkGroup.find_by_id(wg.id)
    wg=WorkGroup.all.first
    assert_same 1,wg.project_id
  end

  test "to_rdf" do
    object = Factory :project, :web_page=>"http://www.sysmo-db.org",
                     :organisms=>[Factory(:organism), Factory(:organism)]
    Factory :data_file,:projects=>[object]
    Factory :data_file,:projects=>[object]
    Factory :model,:projects=>[object]
    Factory :sop,:projects=>[object]
    Factory :presentation, :projects=>[object]
    i = Factory :investigation, :projects=>[object]
    s = Factory :study, :investigation=>i
    Factory :assay, :study=>s
    wg = Factory :work_group,:project=>object
    Factory :group_membership,:work_group=>wg,:person=>Factory(:person)

    object.reload
    assert !object.people.empty?
    rdf = object.to_rdf
    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count > 1
      assert_equal RDF::URI.new("http://localhost:3000/projects/#{object.id}"), reader.statements.first.subject
    end
  end

  test "rdf with empty URI resource" do
    object = Factory :project, :web_page=>"http://google.com"

    homepage_predicate = RDF::URI.new "http://xmlns.com/foaf/0.1/homepage"
    found = false
    RDF::Reader.for(:rdfxml).new(object.to_rdf) do |reader|
      reader.each_statement do |statement|
        if statement.predicate == homepage_predicate
          found = true
          assert statement.valid?, "statement is not valid"
          assert_equal RDF::URI.new("http://google.com"),statement.object
        end
      end
    end
    assert found,"Didn't find homepage predicate"

    object.web_page=""
    found = false
    RDF::Reader.for(:rdfxml).new(object.to_rdf) do |reader|
      reader.each_statement do |statement|
        if statement.predicate == homepage_predicate
          found = true

          assert statement.valid?, "statement is not valid"
        end
      end
    end
    assert !found,"The homepage statement should have been skipped"
  end

  def test_avatar_key
    p=projects(:sysmo_project)
    assert_nil p.avatar_key
    assert p.defines_own_avatar?
  end

  test "has_member" do
    person = Factory :person
    project = person.projects.first
    other_person = Factory :person
    assert project.has_member?(person)
    assert project.has_member?(person.user)
    assert !project.has_member?(other_person)
    assert !project.has_member?(other_person.user)
    assert !project.has_member?(nil)
  end

  def test_ordered_by_name
    assert Project.all.sort_by {|p| p.name.downcase} == Project.default_order || Project.all.sort_by {|p| p.name} == Project.default_order
  end

  def test_title_alias_for_name
    p=projects(:sysmo_project)
    assert_equal p.name,p.title
  end

  def test_title_trimmed 
   p=Project.new(:title=>" test project")
   p.save!
   assert_equal("test project",p.title)
  end

  def test_set_credentials
    p=Project.new(:title=>"test project")
    p.site_password="12345"
    p.site_username="fred"
    p.save!
    assert_not_nil p.site_credentials
  end

  def test_decrypt_credentials
    p=projects(:sysmo_project)
    p.site_password="12345"
    p.site_username="fred"
    p.save!

    p=Project.find(p.id)
    assert_nil p.site_username, "site username should be nil until requested"
    assert_nil p.site_password, "site password should be nil until requested"

    p.decrypt_credentials
    assert_equal "fred",p.site_username
    assert_equal "12345",p.site_password
  end

  def test_credentials_not_updated_unless_password_and_username_provided
    p=Project.new(:title=>"fred")
    p.site_password="12345"
    p.site_username="fred"
    p.save!
    cred=p.site_credentials
    p=Project.find(p.id)
    assert_equal cred,p.site_credentials
    assert_nil p.site_password
    assert_nil p.site_username
    p.save!
    assert_equal cred,p.site_credentials
    p=Project.find(p.id)
    assert_equal cred,p.site_credentials
  end
  
  def test_publications_association
    project=projects(:sysmo_project)

    assert_equal 3,project.publications.count
    
    assert project.publications.include?(publications(:one))
    assert project.publications.include?(publications(:pubmed_2))
    assert project.publications.include?(publications(:taverna_paper_pubmed))
  end

  def test_projects_with_userless_people
    projects=Project.with_userless_people
    assert_not_nil projects, "The list should not be nil"
    assert projects.instance_of?(Array),"The results should be an array"
    assert projects.size>0, "There should be some projects in the list"
    p1 = projects(:one)    
    assert projects.include?(p1),"The list of projects that have userless people should include Project :one"
    p2 = projects(:two)      
    assert !projects.include?(p2), "Project :two should not be in the list of projects without users"
    p4 = projects(:four)
    assert !projects.include?(p4), "Project :four should not be included as it does not contain any people"
  end

  def test_userless_people
    proj1=projects(:one)
    assert_not_nil proj1.userless_people
    assert proj1.userless_people.size>0
    p3=people(:three)
    assert proj1.userless_people.include?(p3),"Project :one should include person :three as a userless person"

    proj2=projects(:two)
    assert_not_nil proj2.userless_people, "Even though a project does not contain userless people, it should return an empty list, not nil"
    assert_equal 0,proj2.userless_people.size,"Project :two should contain NO userless people"
    
  end

  def test_can_be_edited_by
    u=users(:can_edit)
    p=projects(:three)
    assert p.can_be_edited_by?(u),"Project :three should be editable by user :can_edit"

    p=projects(:four)
    assert !p.can_be_edited_by?(u),"Project :four should not be editable by user :can_edit as he is not a member"

    u=users(:quentin)
    assert p.can_be_edited_by?(u),"Project :four should be editable by user :quentin as he's an admin"

    u=users(:cant_edit)
    p=projects(:three)
    assert !p.can_be_edited_by?(u),"Project :three should not be editable by user :cant_edit"

    u=Factory(:project_manager).user
    p=u.person.projects.first
    assert p.can_be_edited_by?(u),"Project :three should be editable by user :project_manager"

    p=projects(:four)
    assert !p.can_be_edited_by?(u),"Project :four should not be editable by user :can_edit as he is not a member"
  end

  test "can be administered by" do
    admin = Factory(:admin)
    pm = Factory(:project_manager)
    normal = Factory(:person)
    another_proj = Factory(:project)

    assert pm.projects.first.can_be_administered_by?(pm.user)
    assert !normal.projects.first.can_be_administered_by?(normal.user)

    assert !another_proj.can_be_administered_by?(normal.user)
    assert !another_proj.can_be_administered_by?(pm.user)
    assert another_proj.can_be_administered_by?(admin.user)
  end

  def test_update_first_letter
    p=Project.new(:name=>"test project")
    p.save
    assert_equal "T",p.first_letter
  end

  def test_valid
    p=projects(:one)    

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

    p.wiki_page=nil
    assert p.valid?

    p.wiki_page=""
    assert p.valid?

    p.wiki_page="sdfsdf"
    assert !p.valid?

    p.wiki_page="http://google.com"
    assert p.valid?

    p.wiki_page="https://google.com"
    assert p.valid?

    p.wiki_page="http://google.com/fred"
    assert p.valid?

    p.wiki_page="http://google.com/fred?param=bob"
    assert p.valid?

    p.wiki_page="http://www.mygrid.org.uk/dev/issues/secure/IssueNavigator.jspa?reset=true&mode=hide&sorter/order=DESC&sorter/field=priority&resolution=-1&pid=10051&fixfor=10110"
    assert p.valid?

    p.name=nil
    assert !p.valid?

    p.name=""
    assert !p.valid?

    p.name="fred"
    assert p.valid?
  end

  test "test uuid generated" do
    p = projects(:one)
    assert_nil p.attributes["uuid"]
    p.save
    assert_not_nil p.attributes["uuid"]
  end
  
  test "uuid doesn't change" do
    x = projects(:one)
    x.save
    uuid = x.attributes["uuid"]
    x.save
    assert_equal x.uuid, uuid
  end

  test "Should order Latest list of projects by updated_at" do
    project1 = Factory(:project, :name => 'C', :updated_at => 2.days.ago)
    project2 = Factory(:project, :name => 'B', :updated_at => 1.days.ago)

    latest_projects = Project.paginate_after_fetch([project1,project2], :page=>'latest')
    assert_equal project2, latest_projects.first
  end

  test "can_delete?" do
    project = Factory(:project)

    #none-admin can not delete
    user = Factory(:user)
    assert !user.is_admin?
    assert project.work_groups.collect(&:people).flatten.empty?
    assert !project.can_delete?(user)

    #can not delete if workgroups contain people
    user = Factory(:admin).user
    assert user.is_admin?
    project = Factory(:project)
    work_group = Factory(:work_group, :project => project)
    a_person = Factory(:person, :group_memberships => [Factory(:group_membership, :work_group => work_group)])
    assert !project.work_groups.collect(&:people).flatten.empty?
    assert !project.can_delete?(user)

    #can delete if admin and workgroups are empty
    work_group.group_memberships.delete_all
    assert project.work_groups.reload.collect(&:people).flatten.empty?
    assert user.is_admin?
    assert project.can_delete?(user)
  end

  test "gatekeepers" do
    User.with_current_user(Factory(:admin)) do
      person=Factory(:person_in_multiple_projects)
      proj1 = person.projects.first
      proj2 = person.projects.last
      person.is_gatekeeper=true,proj1
      person.save!

      assert proj1.gatekeepers.include?(person)
      assert !proj2.gatekeepers.include?(person)
    end
  end

  test "project_managers" do
    User.with_current_user(Factory(:admin)) do
      person=Factory(:person_in_multiple_projects)
      proj1 = person.projects.first
      proj2 = person.projects.last
      person.is_project_manager=true,proj1
      person.save!

      assert proj1.project_managers.include?(person)
      assert !proj2.project_managers.include?(person)
    end
  end

  test "project_cordinators" do
    User.with_current_user(Factory(:admin)) do
      person=Factory(:person_in_multiple_projects)
      proj1 = person.projects.first
      proj2 = person.projects.last
      person.is_project_cordinator=true,proj1
      person.save!

      assert proj1.project_cordinators.include?(person)
      assert !proj2.project_cordinators.include?(person)
    end
  end

  test "asset_managers" do
    User.with_current_user(Factory(:admin)) do
      person=Factory(:person_in_multiple_projects)
      proj1 = person.projects.first
      proj2 = person.projects.last
      person.is_asset_manager=true,proj1
      person.save!

      assert proj1.asset_managers.include?(person)
      assert !proj2.asset_managers.include?(person)
    end
  end

  test "pals" do
    User.with_current_user(Factory(:admin)) do
      person=Factory(:person_in_multiple_projects)
      proj1 = person.projects.first
      proj2 = person.projects.last
      person.is_pal=true,proj1
      person.save!

      assert proj1.pals.include?(person)
      assert !proj2.pals.include?(person)
    end
  end
end
