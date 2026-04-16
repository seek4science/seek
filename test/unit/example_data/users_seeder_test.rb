require 'test_helper'

class UsersSeederTest < ActiveSupport::TestCase
  def setup
    User.delete_all
    Person.delete_all
    disable_std_output
    @projects_seeder = Seek::ExampleData::ProjectsSeeder.new
    base_data = @projects_seeder.seed
    @workgroup = base_data[:workgroup]
    @project = base_data[:project]
    @institution = base_data[:institution]
  end

  def teardown
    enable_std_output
  end

  test 'seeds users and people' do
    
    seeder = Seek::ExampleData::UsersSeeder.new(
      @workgroup,
      @project,
      @institution
    )
    result = seeder.seed
    
    # Check that result hash has expected keys
    assert_includes result.keys, :admin_user
    assert_includes result.keys, :admin_person
    assert_includes result.keys, :guest_user
    assert_includes result.keys, :guest_person
    
    # Check that users were created
    assert_not_nil result[:admin_user]
    assert_not_nil result[:guest_user]
    
    # Verify admin user
    admin_user = result[:admin_user].reload
    assert_equal 'admin', admin_user.login
    assert admin_user.active?
    assert_not_nil admin_user.person
    assert_equal 'Admin', admin_user.person.first_name
    assert admin_user.is_admin?
    
    # Verify guest user
    guest_user = result[:guest_user].reload
    assert_equal 'guest', guest_user.login
    assert guest_user.active?
    assert_not_nil guest_user.person
    assert_equal 'Guest', guest_user.person.first_name
    refute guest_user.is_admin?

    admin_person = result[:admin_person].reload
    assert_equal 'Admin', admin_person.first_name
    assert_equal 'User', admin_person.last_name
    assert_equal 'https://orcid.org/0000-0002-1825-0097', admin_person.orcid_uri
    assert_equal 'https://example.org', admin_person.web_page
    assert_equal '00-0000-0000-0000', admin_person.phone
    assert_equal ['administration', 'data management'], admin_person.expertise
    assert_equal ['SEEK', 'Ruby on Rails'], admin_person.tools

    guest_person = result[:guest_person].reload
    assert_equal 'Guest', guest_person.first_name
    assert_equal 'User', guest_person.last_name

    # Verify people are in workgroup
    assert_includes admin_person.work_groups, @workgroup
    assert_includes guest_person.work_groups, @workgroup
    
    # Verify project was updated
    project = @project.reload
    assert_includes project.pals, guest_person

  end
end
