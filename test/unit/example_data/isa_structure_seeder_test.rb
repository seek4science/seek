require 'test_helper'

class ISAStructureSeederTest < ActiveSupport::TestCase
  def setup
    FactoryBot.create(:experimental_assay_class)
    FactoryBot.create(:modelling_assay_class)
    disable_std_output
    @projects_seeder = Seek::ExampleData::ProjectsSeeder.new
    base_data = @projects_seeder.seed
    @project = base_data[:project]
    @organism = base_data[:organism]
    
    @users_seeder = Seek::ExampleData::UsersSeeder.new(
      base_data[:workgroup],
      base_data[:project],
      base_data[:institution]
    )
    user_data = @users_seeder.seed
    @guest_person = user_data[:guest_person]
    @admin_person = user_data[:admin_person]
  end

  def teardown
    enable_std_output
  end

  test 'seeds ISA structure' do
    
    seeder = Seek::ExampleData::ISAStructureSeeder.new(
      @project,
      @guest_person,
      @admin_person,
      @organism
    )
    result = nil
    assert_difference('Assay.count', 3) do
      assert_difference('Study.count', 1) do
        assert_difference('ObservationUnit.count', 1) do
          assert_difference('Investigation.count', 1) do
            result = seeder.seed
          end
        end
      end
    end
    
    # Check that result hash has expected keys
    assert_includes result.keys, :investigation
    assert_includes result.keys, :study
    assert_includes result.keys, :observation_unit
    assert_includes result.keys, :exp_assay
    assert_includes result.keys, :model_assay
    assert_includes result.keys, :assay_stream
    
    # Check investigation
    investigation = result[:investigation].reload
    assert_not_nil investigation
    assert_equal 'Central Carbon Metabolism of Sulfolobus solfataricus', investigation.title
    assert_includes investigation.projects, @project
    assert_equal @guest_person, investigation.contributor
    assert_equal [@admin_person], investigation.creators
    assert_equal 'Person A, Person B', investigation.other_creators
    assert_equal %w[metabolism thermophile], investigation.tags
    
    # Check study
    study = result[:study].reload
    assert_not_nil study
    assert_equal 'Carbon loss at high T', study.title
    assert_equal 'The carbon loss at high T description will be here but I am currently not imaginative enough.', study.description
    assert_equal ['thermophile', 'high temperature'].sort, study.tags.sort
    assert_equal investigation, study.investigation
    assert_equal @guest_person, study.contributor
    
    # Check observation unit
    observation_unit = result[:observation_unit].reload
    assert_not_nil observation_unit
    assert_equal 'Large scale bioreactor', observation_unit.title
    assert_equal study, observation_unit.study
    assert_equal @guest_person, observation_unit.contributor
    assert_equal ['bioreactor'], observation_unit.tags
    
    # Check experimental assay
    exp_assay = result[:exp_assay].reload
    assert_not_nil exp_assay
    assert_equal 'Reconstituted system reference state', exp_assay.title
    assert_equal study, exp_assay.study
    assert_equal AssayClass.experimental, exp_assay.assay_class
    assert_includes exp_assay.organisms, @organism
    assert_equal @guest_person, exp_assay.contributor
    
    # Check modelling assay
    model_assay = result[:model_assay].reload
    assert_not_nil model_assay
    assert_equal 'Model reconstituted system', model_assay.title
    assert_equal study, model_assay.study
    assert_equal AssayClass.modelling, model_assay.assay_class
    assert_equal @guest_person, model_assay.contributor
    
    # Check assay stream
    assay_stream = result[:assay_stream].reload
    assert_not_nil assay_stream
    assert_equal 'Assay stream', assay_stream.title
    assert_equal AssayClass.assay_stream, assay_stream.assay_class
  end
end
