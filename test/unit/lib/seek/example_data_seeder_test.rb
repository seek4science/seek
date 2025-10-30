require 'test_helper'

class ExampleDataSeederTest < ActiveSupport::TestCase
  def setup
    User.current_user = nil
  end

  def teardown
    User.current_user = nil
  end

  test 'can create ExampleDataSeeder instance' do
    seeder = Seek::ExampleDataSeeder.new
    assert_not_nil seeder
  end

  test 'responds to seed_all method' do
    seeder = Seek::ExampleDataSeeder.new
    assert_respond_to seeder, :seed_all
  end
  
  test 'has attr_readers for all seeded data' do
    seeder = Seek::ExampleDataSeeder.new
    
    # Check project-related attributes
    assert_respond_to seeder, :project
    assert_respond_to seeder, :program
    assert_respond_to seeder, :institution
    assert_respond_to seeder, :workgroup
    
    # Check user-related attributes
    assert_respond_to seeder, :admin_user
    assert_respond_to seeder, :guest_user
    assert_respond_to seeder, :admin_person
    assert_respond_to seeder, :guest_person
    
    # Check ISA-related attributes
    assert_respond_to seeder, :investigation
    assert_respond_to seeder, :study
    assert_respond_to seeder, :exp_assay
    
    # Check sample-related attributes
    assert_respond_to seeder, :culture_sample_type
    assert_respond_to seeder, :enzyme_sample_type
    
    # Check asset-related attributes
    assert_respond_to seeder, :data_file1
    assert_respond_to seeder, :model
    assert_respond_to seeder, :sop
    assert_respond_to seeder, :publication
  end
end
