require 'test_helper'

class IsaStructureSeederTest < ActiveSupport::TestCase
  def setup
    User.current_user = nil
    @projects_seeder = Seek::ExampleData::ProjectsSeeder.new
    @base_data = @projects_seeder.seed
    
    @users_seeder = Seek::ExampleData::UsersSeeder.new(
      @base_data[:workgroup],
      @base_data[:project],
      @base_data[:institution]
    )
    @user_data = @users_seeder.seed
  end

  def teardown
    User.current_user = nil
  end

  test 'seeds ISA structure' do
    initial_investigation_count = Investigation.count
    initial_study_count = Study.count
    initial_assay_count = Assay.count
    
    seeder = Seek::ExampleData::IsaStructureSeeder.new(
      @base_data[:project],
      @user_data[:guest_person],
      @base_data[:organism]
    )
    result = seeder.seed
    
    # Check that result hash has expected keys
    assert_includes result.keys, :investigation
    assert_includes result.keys, :study
    assert_includes result.keys, :observation_unit
    assert_includes result.keys, :exp_assay
    assert_includes result.keys, :model_assay
    assert_includes result.keys, :assay_stream
    
    # Check investigation
    investigation = result[:investigation]
    assert_not_nil investigation
    assert_equal 'Central Carbon Metabolism of Sulfolobus solfataricus', investigation.title
    assert_includes investigation.projects, @base_data[:project]
    
    # Check study
    study = result[:study]
    assert_not_nil study
    assert_equal 'Carbon loss at high T', study.title
    assert_equal investigation, study.investigation
    
    # Check observation unit
    observation_unit = result[:observation_unit]
    assert_not_nil observation_unit
    assert_equal 'Large scale bioreactor', observation_unit.title
    assert_equal study, observation_unit.study
    
    # Check experimental assay
    exp_assay = result[:exp_assay]
    assert_not_nil exp_assay
    assert_equal 'Reconstituted system reference state', exp_assay.title
    assert_equal study, exp_assay.study
    assert_equal AssayClass.experimental, exp_assay.assay_class
    assert_includes exp_assay.organisms, @base_data[:organism]
    
    # Check modelling assay
    model_assay = result[:model_assay]
    assert_not_nil model_assay
    assert_equal 'Model reconstituted system', model_assay.title
    assert_equal study, model_assay.study
    assert_equal AssayClass.modelling, model_assay.assay_class
    
    # Check assay stream
    assay_stream = result[:assay_stream]
    assert_not_nil assay_stream
    assert_equal 'Assay stream', assay_stream.title
    assert_equal AssayClass.assay_stream, assay_stream.assay_class
  end
end
