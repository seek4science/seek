require 'test_helper'

class InstitutionTest < ActiveSupport::TestCase

  fixtures :institutions,:projects,:work_groups,:users,:group_memberships, :people
  # Replace this with your real tests.

  def test_delete_inst_deletes_workgroup
    n_wg = WorkGroup.count
    n_inst = Institution.count
    
    i=Institution.find(1)
    
    assert_equal 1,i.work_groups.size

    wg = i.work_groups.first
    wg.people=[]
    User.current_user = Factory(:admin).user
    i.destroy
    assert_equal nil, Institution.find_by_id(i.id)
    assert_equal nil, WorkGroup.find_by_id(wg.id), "the workgroup should also have been destroyed"
  end

  test "programmes" do
    proj1=Factory(:work_group).project
    proj2=Factory(:work_group).project
    proj3=Factory(:work_group).project

    refute_empty proj1.institutions
    refute_empty proj2.institutions
    refute_empty proj3.institutions

    prog1 = Factory(:programme,:projects=>[proj1,proj2])
    assert_includes proj1.institutions.first.programmes,prog1
    assert_includes proj2.institutions.first.programmes,prog1
    refute_includes proj3.institutions.first.programmes,prog1
  end

  def test_ordered_by_title
    assert Institution.all.sort_by {|i| i.title.downcase} == Institution.default_order || Institution.all.sort_by {|i|i.title} == Institution.default_order
  end

  test "to_rdf" do
    object = Factory :institution
    rdf = object.to_rdf

    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count >= 1
      assert_equal RDF::URI.new("http://localhost:3000/institutions/#{object.id}"), reader.statements.first.subject
    end
  end

  def test_avatar_key
    i=institutions(:one)
    assert_nil i.avatar_key
    assert i.defines_own_avatar?
  end

  def test_title_trimmed
    i=Institution.new(:title=>" an institution", :country => 'Ghana')
    i.save!
    assert_equal("an institution",i.title) 
  end
  
  def test_update_first_letter
    i=Institution.new(:title=>"an institution", :country => 'Serbia')
    i.save
    assert_equal "A",i.first_letter
  end

  def test_can_be_edited_by

    pm = Factory(:project_administrator)
    i = pm.institutions.first
    i2 = Factory(:institution)
    assert i.can_be_edited_by?(pm.user), "This institution should be editable as this user is project administrator of a project this institution is linked to"
    assert !i2.can_be_edited_by?(pm.user), "This institution should be not editable as this user is project administrator but not of a project this institution is linked to"

    i=Factory(:institution)
    u=Factory(:admin).user
    assert i.can_be_edited_by?(u),"Institution :one should be editable by this user, as he's an admin"

  end

  def test_valid
    i=Factory(:institution)
    assert i.valid?

    i.title=nil
    assert !i.valid?

    i.title=""
    assert !i.valid?

    i.title="Name"
    assert i.valid?

    i.web_page=nil
    assert i.valid?

    i.web_page=""
    assert i.valid?

    i.web_page="sdfsdf"
    assert !i.valid?

    i.web_page="http://google.com"
    assert i.valid?

    i.web_page="https://google.com"
    assert i.valid?

    i.web_page="http://google.com/fred"
    assert i.valid?

    i.web_page="http://google.com/fred?param=bob"
    assert i.valid?

    i.web_page="http://www.mygrid.org.uk/dev/issues/secure/IssueNavigator.jspa?reset=true&mode=hide&sorter/order=DESC&sorter/field=priority&resolution=-1&pid=10051&fixfor=10110"
    assert i.valid?


  end

  test "test uuid generated" do
    i = institutions(:one)
    assert_nil i.attributes["uuid"]
    i.save
    assert_not_nil i.attributes["uuid"]
  end 
  
  test "uuid doesn't change" do
    x = institutions(:one)
    x.save
    uuid = x.attributes["uuid"]
    x.save
    assert_equal x.uuid, uuid
  end

  test "can_delete?" do
    institution = Factory(:institution)

    #none-admin can not delete
    user = Factory(:user)
    assert !user.is_admin?
    assert institution.work_groups.collect(&:people).flatten.empty?
    assert !institution.can_delete?(user)

    #can not delete if workgroups contain people
    user = Factory(:admin).user
    assert user.is_admin?
    institution = Factory(:project)
    work_group = Factory(:work_group, :project => institution)
    a_person = Factory(:person, :group_memberships => [Factory(:group_membership, :work_group => work_group)])
    assert !institution.work_groups.collect(&:people).flatten.empty?
    assert !institution.can_delete?(user)

    #can delete if admin and workgroups are empty
    work_group.group_memberships.delete_all
    assert institution.work_groups.reload.collect(&:people).flatten.empty?
    assert user.is_admin?
    assert institution.can_delete?(user)
  end

  test "get all institution listing" do
    inst = Factory(:institution,:title=>"Inst X")
    array = Institution.get_all_institutions_listing
    assert_include array,["Inst X",inst.id]
  end

  test "can create?" do
    User.current_user=nil
    refute Institution.can_create?

    User.current_user = Factory(:person).user
    refute Institution.can_create?

    User.current_user = Factory(:admin).user
    assert Institution.can_create?

    User.current_user = Factory(:project_administrator).user
    assert Institution.can_create?

    person = Factory(:programme_administrator)
    User.current_user = person.user
    programme = person.administered_programmes.first
    assert programme.is_activated?
    assert Institution.can_create?

    #only if the programme is activated
    person = Factory(:programme_administrator)
    programme = person.administered_programmes.first
    programme.is_activated=false
    disable_authorization_checks{programme.save!}
    User.current_user = person.user
    refute Institution.can_create?
  end
end
