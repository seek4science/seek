require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  
  fixtures :projects, :institutions, :work_groups, :group_memberships, :people, :users, :taggings, :tags, :publications, :assets, :organisms
  
  #checks that the dependent work_groups are destoryed when the project s
  def test_delete_work_groups_when_project_deleted
    n_wg=WorkGroup.find(:all).size
    p=Project.find(2)
    assert_equal 1,p.work_groups.size
        
    p.work_groups.first.people=[]
    p.save!
    p.destroy
    
    assert_equal n_wg-1,WorkGroup.find(:all).size
    wg=WorkGroup.find(:all).first
    assert_same 1,wg.project_id
  end

  def test_avatar_key
    p=projects(:sysmo_project)
    assert_nil p.avatar_key
    assert p.defines_own_avatar?
  end

  def test_ordered_by_name
    assert Project.find(:all).sort_by {|p| p.name.downcase} == Project.find(:all) || Project.all.sort_by {|p| p.name} == Project.all
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

    u=users(:project_manager)
    assert p.can_be_edited_by?(u),"Project :three should be editable by user :project_manager"

    p=projects(:four)
    assert !p.can_be_edited_by?(u),"Project :four should not be editable by user :can_edit as he is not a member"
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

  def test_pals
    pal=people(:pal)
    project=projects(:sysmo_project)

    assert_equal 1,project.pals.size
    assert project.pals.include?(pal)

    project = projects(:moses_project)
    assert !project.pals.include?(pal)
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
end
