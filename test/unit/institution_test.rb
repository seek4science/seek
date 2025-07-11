require 'test_helper'

class InstitutionTest < ActiveSupport::TestCase

  include MockHelper

  fixtures :institutions, :projects, :work_groups, :users, :group_memberships, :people

  def setup
    ror_mock
  end
  # Replace this with your real tests.

  def test_delete_inst_deletes_workgroup
    i = FactoryBot.create(:person).institutions.first

    assert_equal 1, i.work_groups.size

    wg = i.work_groups.first
    wg.people = []
    User.with_current_user(FactoryBot.create(:admin).user) do
      i.destroy
    end

    assert_nil Institution.find_by_id(i.id)
    assert_nil WorkGroup.find_by_id(wg.id), 'the workgroup should also have been destroyed'
  end

  test 'programmes' do
    proj1 = FactoryBot.create(:work_group).project
    proj2 = FactoryBot.create(:work_group).project
    proj3 = FactoryBot.create(:work_group).project

    refute_empty proj1.institutions
    refute_empty proj2.institutions
    refute_empty proj3.institutions

    prog1 = FactoryBot.create(:programme, projects: [proj1, proj2])
    assert_includes proj1.institutions.first.programmes, prog1
    assert_includes proj2.institutions.first.programmes, prog1
    refute_includes proj3.institutions.first.programmes, prog1
  end

  def test_avatar_key
    i = institutions(:one)
    assert_nil i.avatar_key
    assert i.defines_own_avatar?
  end

  def test_title_trimmed
    i = FactoryBot.create(:institution, title: ' an institution', country: 'LY')
    assert_equal('an institution', i.title)
  end

  test 'title combines title and department correctly' do

    assert_equal 'Science, University', FactoryBot.create(:institution, title: 'University', department: 'Science').title
    assert_equal 'University', FactoryBot.create(:institution, title: 'University', department: '').title
    assert_equal 'University', FactoryBot.create(:institution, title: 'University', department: nil).title
    assert_equal 'A Minimal Institution', FactoryBot.create(:min_institution).title
    assert_equal 'Manchester Institute of Biotechnology, University of Manchester', FactoryBot.create(:max_institution).title
  end

  def test_update_first_letter
    i = FactoryBot.create(:institution, title: 'an institution', country: 'NL')
    assert_equal 'A', i.first_letter
  end

  def test_can_be_edited_by
    prog_admin = FactoryBot.create(:programme_administrator)
    pm = FactoryBot.create(:project_administrator)
    i = pm.institutions.first
    i2 = FactoryBot.create(:institution)
    assert i.can_edit?(pm.user), 'This institution should be editable as this user is project administrator of a project this institution is linked to'
    assert i2.can_edit?(pm.user), 'This institution should be editable as this user is project administrator, even if not of a project this institution is linked to'
    assert i.can_edit?(prog_admin.user), 'This institution should be editable as this user is programme administrator'

    person = FactoryBot.create(:person)
    refute i.can_edit?(person), 'The institution should not be editable by a normal person'
    i = person.institutions.first
    refute i.can_edit?(person), 'The institution should not be editable by a normal person even if a member'

    i = FactoryBot.create(:institution)
    u = FactoryBot.create(:admin).user
    assert i.can_edit?(u), "Institution :one should be editable by this user, as he's an admin"
  end

  test 'validation' do

    i = FactoryBot.create(:institution)
    assert i.valid?

    i.title = nil
    assert !i.valid?

    i.title = ''
    assert !i.valid?

    i.title = 'Name'
    assert i.valid?

    i.web_page = nil
    assert i.valid?

    i.web_page = ''
    assert i.valid?

    i.web_page = 'sdfsdf'
    assert !i.valid?

    i.web_page = 'http://google.com'
    assert i.valid?

    i.web_page = 'https://google.com'
    assert i.valid?

    # gets stripped before validation
    i.web_page = '  https://google.com   '
    assert i.valid?
    assert_equal 'https://google.com', i.web_page

    i.web_page = 'http://google.com/fred'
    assert i.valid?

    i.web_page = 'http://google.com/fred?param=bob'
    assert i.valid?

    i.web_page = 'http://www.mygrid.org.uk/dev/issues/secure/IssueNavigator.jspa?reset=true&mode=hide&sorter/order=DESC&sorter/field=priority&resolution=-1&pid=10051&fixfor=10110'
    assert i.valid?

    i.ror_id='027m9bs27'
    assert i.valid?

    i.ror_id = ''
    assert i.valid?

    i.ror_id = '1121'
    assert !i.valid?

    i.ror_id = '1121-1121-1121'
    assert !i.valid?

    #duplicate ror_id
    existing_institution = FactoryBot.create(:institution, ror_id: '027m9bs27')
    new_institution = FactoryBot.build(:institution, ror_id: existing_institution.ror_id)
    assert_not new_institution.valid?
  end

  test 'test uuid generated' do
    i = institutions(:one)
    assert_nil i.attributes['uuid']
    i.save
    assert_not_nil i.attributes['uuid']
  end

  test "uuid doesn't change" do
    x = institutions(:one)
    x.save
    uuid = x.attributes['uuid']
    x.save
    assert_equal x.uuid, uuid
  end

  test 'can_delete?' do
    institution = FactoryBot.create(:institution)

    # none-admin can not delete
    user = FactoryBot.create(:user)
    assert !user.is_admin?
    assert institution.work_groups.collect(&:people).flatten.empty?
    assert !institution.can_delete?(user)

    # can not delete if workgroups contain people
    user = FactoryBot.create(:admin).user
    assert user.is_admin?
    institution = FactoryBot.create(:project)
    work_group = FactoryBot.create(:work_group, project: institution)
    a_person = FactoryBot.create(:person, group_memberships: [FactoryBot.create(:group_membership, work_group: work_group)])
    # assert !institution.work_groups.collect(&:people).flatten.empty?
    # assert !institution.can_delete?(user)

    # can delete if admin and workgroups are empty
    work_group.group_memberships.delete_all
    assert institution.work_groups.reload.collect(&:people).flatten.empty?
    assert user.is_admin?
    assert institution.can_delete?(user)
  end

  test 'get all institution listing' do
    inst = FactoryBot.create(:institution, title: 'Inst X')
    array = Institution.get_all_institutions_listing
    assert_includes array, ['Inst X', inst.id]
  end

  test 'can create?' do
    User.current_user = nil
    refute Institution.can_create?

    User.current_user = FactoryBot.create(:person).user
    refute Institution.can_create?

    User.current_user = FactoryBot.create(:admin).user
    assert Institution.can_create?

    User.current_user = FactoryBot.create(:project_administrator).user
    assert Institution.can_create?

    person = FactoryBot.create(:programme_administrator)
    User.current_user = person.user
    programme = person.administered_programmes.first
    assert programme.is_activated?
    assert Institution.can_create?

    # only if the programme is activated
    person = FactoryBot.create(:programme_administrator)
    programme = person.administered_programmes.first
    programme.is_activated = false
    disable_authorization_checks { programme.save! }
    User.current_user = person.user
    refute Institution.can_create?
  end

  test "can list people even if they don't have a last name" do
    work_group = FactoryBot.create(:work_group)
    person = FactoryBot.create(:person, last_name: nil, group_memberships: [FactoryBot.create(:group_membership, work_group: work_group)])
    person2 = FactoryBot.create(:person, group_memberships: [FactoryBot.create(:group_membership, work_group: work_group)])

    assert_includes work_group.institution.people, person
  end

  test 'country conversion and validation' do
    institution = FactoryBot.build(:institution, country: nil)
    assert institution.valid?
    assert institution.country.nil?

    institution.country = ''
    assert institution.valid?

    institution.country = 'GB'
    assert institution.valid?
    assert_equal 'GB', institution.country

    institution.country = 'gb'
    assert institution.valid?
    assert_equal 'GB', institution.country

    institution.country = 'Germany'
    assert institution.valid?
    assert_equal 'DE', institution.country

    institution.country = 'FRANCE'
    assert institution.valid?
    assert_equal 'FR', institution.country

    institution.country = 'ZZ'
    refute institution.valid?
    assert_equal 'ZZ', institution.country

    institution.country = 'Land of Oz'
    refute institution.valid?
    assert_equal 'Land of Oz', institution.country

    # check the conversion gets saved
    institution = FactoryBot.build(:institution)
    institution.country = "Germany"
    disable_authorization_checks {
      assert institution.save!
    }
    institution.reload
    assert_equal 'DE',institution.country
  end

  test 'fetch_ror_details is called before validation' do
    institution = Institution.new(ror_id: '027m9bs27')
    institution.valid?
    assert_equal 'University of Manchester', institution.title
    assert_equal 'Manchester', institution.city
    assert_equal 'GB', institution.country
    assert_equal 'http://www.manchester.ac.uk/', institution.web_page
  end

  test 'fetch_ror_details adds error if ROR ID is invalid' do
    institution = Institution.new(ror_id: 'invalid_id')
    institution.valid?
    assert_includes institution.errors[:ror_id], "'invalid_id' is not a valid ROR ID"
  end

end
