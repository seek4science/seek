require 'test_helper'

class PersonTest < ActiveSupport::TestCase
  fixtures :people, :projects,:institutions, :work_groups, :group_memberships,:users, :tags,:taggings,:disciplines
  
  # Replace this with your real tests.
  def test_work_groups
    p=people(:one)
    assert_equal 2,p.work_groups.size
  end

  def test_registered
    registered=Person.registered
    registered.each do |p|
      assert_not_nil p.user
    end
    assert registered.include?(people(:one))
    assert !registered.include?(people(:person_without_user))
  end

  def test_without_group
    without_group=Person.without_group
    without_group.each do |p|
      assert_equal 0,p.group_memberships.size
    end
    assert !without_group.include?(people(:one))
    assert without_group.include?(people(:person_without_group))
  end

  def test_expertise
    p=people(:one)
    assert_equal 2, p.expertise.size

    p=people(:two)
    assert_equal 1, p.expertise.size
    assert_equal "golf",p.expertise[0].name
  end
  
  def test_institutions
    p=people(:one)
    assert_equal 2,p.institutions.size
    
    p=people(:two)
    assert_equal 2,p.work_groups.size
    assert_equal 2,p.projects.size
    assert_equal 1,p.institutions.size
  end
  
  def test_projects
    p=people(:one)
    assert_equal 2,p.projects.size
  end
  
  def test_userless_people
    peeps=Person.userless_people
    assert_not_nil peeps
    assert peeps.size>0,"There should be some userless people"
    assert_nil peeps.find{|p| !p.user.nil?},"There should be no people with a non nil user"    

    p=people(:three)
    assert_not_nil peeps.find{|person| p.id==person.id},"Person :three should be userless and therefore in the list"

    p=people(:one)
    assert_nil peeps.find{|person| p.id==person.id},"Person :one should have a user and not be in the list"
  end

  def test_name
      p=people(:one)
      assert_equal "Quentin Jones", p.name
      p.first_name="Tom"
      assert_equal "Tom Jones", p.name
  end

  def test_email_with_name
    p=people(:one)
    assert_equal("Quentin Jones <quentin@email.com>",p.email_with_name)
  end
  
  def test_capitalization_with_nil_last_name
    p=people(:no_first_name)
    assert_equal " Lastname",p.name
  end

  def test_capitalization_with_nil_first_name
    p=people(:no_last_name)
    assert_equal "Firstname ",p.name
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
    p=people(:one)
    assert p.valid?
    p.email=nil
    assert !p.valid?

    p.email="sdf"
    assert !p.valid?

    p.email="sdf@"
    assert !p.valid?

    p.email="sdf@com"
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

  def test_email_unique
    p=people(:one)
    newP=Person.new(:first_name=>"Fred",:email=>p.email)
    assert !newP.valid?,"Should not be valid as email is not unique"
    newP.email="zxczxc@zxczxczxc.com"
    assert newP.valid?
  end

  def test_disciplines
    p=people(:modeller_person)
    assert_equal 2,p.disciplines.size
    assert p.disciplines.include?(disciplines(:modeller))
    assert p.disciplines.include?(disciplines(:experimentalist))
  end


end
