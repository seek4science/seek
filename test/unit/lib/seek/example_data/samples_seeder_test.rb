require 'test_helper'

class SamplesSeederTest < ActiveSupport::TestCase
  def setup
    User.current_user = nil
    
    # Set up base data
    @projects_seeder = Seek::ExampleData::ProjectsSeeder.new
    @base_data = @projects_seeder.seed
    
    @users_seeder = Seek::ExampleData::UsersSeeder.new(
      @base_data[:workgroup],
      @base_data[:project],
      @base_data[:institution]
    )
    @user_data = @users_seeder.seed
    
    @isa_seeder = Seek::ExampleData::IsaStructureSeeder.new(
      @base_data[:project],
      @user_data[:guest_person],
      @base_data[:organism]
    )
    @isa_data = @isa_seeder.seed
  end

  def teardown
    User.current_user = nil
  end

  test 'seeds sample types and samples' do
    initial_sample_type_count = SampleType.count
    initial_sample_count = Sample.count
    
    seeder = Seek::ExampleData::SamplesSeeder.new(
      @base_data[:project],
      @user_data[:guest_person],
      @isa_data[:exp_assay],
      @isa_data[:study]
    )
    result = seeder.seed
    
    # Check that result hash has expected keys
    assert_includes result.keys, :culture_sample_type
    assert_includes result.keys, :enzyme_sample_type
    assert_includes result.keys, :culture1
    assert_includes result.keys, :culture2
    assert_includes result.keys, :enzyme1
    assert_includes result.keys, :enzyme2
    assert_includes result.keys, :enzyme3
    assert_includes result.keys, :enzyme4
    
    # Check sample types
    assert_not_nil result[:culture_sample_type]
    assert_not_nil result[:enzyme_sample_type]
    
    culture_sample_type = result[:culture_sample_type]
    assert_equal 'Bacterial Culture', culture_sample_type.title
    assert_includes culture_sample_type.projects, @base_data[:project]
    
    enzyme_sample_type = result[:enzyme_sample_type]
    assert_equal 'Enzyme Preparation', enzyme_sample_type.title
    assert_includes enzyme_sample_type.projects, @base_data[:project]
    
    # Check samples were created
    assert_not_nil result[:culture1]
    assert_not_nil result[:culture2]
    assert_not_nil result[:enzyme1]
    assert_not_nil result[:enzyme2]
    assert_not_nil result[:enzyme3]
    assert_not_nil result[:enzyme4]
    
    # Verify culture sample
    culture1 = result[:culture1]
    assert_equal 'S. solfataricus Culture #1', culture1.title
    assert_equal culture_sample_type, culture1.sample_type
    
    # Verify enzyme sample
    enzyme1 = result[:enzyme1]
    assert_equal 'Phosphoglycerate Kinase', enzyme1.title
    assert_equal enzyme_sample_type, enzyme1.sample_type
    
    # Check associations
    exp_assay = @isa_data[:exp_assay].reload
    assert_equal 6, exp_assay.samples.count
    assert_includes exp_assay.samples, culture1
    assert_includes exp_assay.samples, enzyme1
    
    study = @isa_data[:study].reload
    assert_includes study.sample_types, culture_sample_type
    assert_includes study.sample_types, enzyme_sample_type
  end
end
