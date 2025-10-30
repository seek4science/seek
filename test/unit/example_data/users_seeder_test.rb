require 'test_helper'

class UsersSeederTest < ActiveSupport::TestCase
  def setup
    User.current_user = nil
    @projects_seeder = Seek::ExampleData::ProjectsSeeder.new
    @base_data = @projects_seeder.seed
  end

  def teardown
    User.current_user = nil
  end

  test 'seeds users and people' do
    initial_user_count = User.count
    initial_person_count = Person.count
    
    seeder = Seek::ExampleData::UsersSeeder.new(
      @base_data[:workgroup],
      @base_data[:project],
      @base_data[:institution]
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
    admin_user = result[:admin_user]
    assert_equal 'admin', admin_user.login
    assert admin_user.active?
    assert_not_nil admin_user.person
    assert_equal 'Admin', admin_user.person.first_name
    
    # Verify guest user
    guest_user = result[:guest_user]
    assert_equal 'guest', guest_user.login
    assert guest_user.active?
    assert_not_nil guest_user.person
    assert_equal 'Guest', guest_user.person.first_name
    
    # Verify people are in workgroup
    assert_includes result[:admin_person].work_groups, @base_data[:workgroup]
    assert_includes result[:guest_person].work_groups, @base_data[:workgroup]
    
    # Verify project was updated
    project = @base_data[:project].reload
    assert_includes project.pals, result[:guest_person]
    
    # Verify institution was updated
    institution = @base_data[:institution].reload
    assert_equal 'GB', institution.country
    assert_equal 'Manchester', institution.city
  end
end
