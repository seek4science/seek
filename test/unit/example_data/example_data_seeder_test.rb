require 'test_helper'

class ExampleDataSeederTest < ActiveSupport::TestCase
  def setup
    User.delete_all
    Person.delete_all
    FactoryBot.create(:journal)
  end

  test 'can create ExampleDataSeeder instance' do
    seeder = Seek::ExampleData::ExampleDataSeeder.new
    assert_not_nil seeder
  end

  test 'responds to seed_all method' do
    seeder = Seek::ExampleData::ExampleDataSeeder.new
    assert_respond_to seeder, :seed_all
  end
  
  test 'has attr_readers for all seeded data' do
    seeder = Seek::ExampleData::ExampleDataSeeder.new
    
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
    assert_respond_to seeder, :culture1
    assert_respond_to seeder, :culture2
    assert_respond_to seeder, :enzyme1
    assert_respond_to seeder, :enzyme2
    assert_respond_to seeder, :enzyme3
    assert_respond_to seeder, :enzyme4
    
    # Check asset-related attributes
    assert_respond_to seeder, :data_file1
    assert_respond_to seeder, :model
    assert_respond_to seeder, :sop
    assert_respond_to seeder, :publication
  end

  test 'seed_all method populates all content' do
    seeder = Seek::ExampleData::ExampleDataSeeder.new
    assert_difference('Programme.count', 1) do
      assert_difference('Project.count', 1) do
        assert_difference('Institution.count', 1) do
          assert_difference('WorkGroup.count', 1) do
            assert_difference('User.count', 2) do
              assert_difference('Person.count', 2) do
                assert_difference('Investigation.count', 1) do
                  assert_difference('Study.count', 1) do
                    assert_difference('Assay.count', 3) do
                      assert_difference('ObservationUnit.count', 1) do
                        assert_difference('SampleType.count', 2) do
                          assert_difference('Sample.count', 6) do
                            assert_difference('DataFile.count', 2) do
                              assert_difference('Model.count', 1) do
                                assert_difference('Sop.count', 1) do
                                  assert_difference('Publication.count', 1) do
                                    seeder.seed_all
                                  end
                                end
                              end
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
    
    # Check that project-related data is populated
    assert_not_nil seeder.project
    assert_not_nil seeder.program
    assert_not_nil seeder.institution
    assert_not_nil seeder.workgroup

    # Check that user-related data is populated
    assert_not_nil seeder.admin_user
    assert_not_nil seeder.guest_user
    assert_not_nil seeder.admin_person
    assert_not_nil seeder.guest_person

    # Check that ISA-related data is populated
    assert_not_nil seeder.investigation
    assert_not_nil seeder.study
    assert_not_nil seeder.exp_assay
    assert_not_nil seeder.model_assay
    assert_not_nil seeder.assay_stream

    # Check that sample-related data is populated
    assert_not_nil seeder.culture_sample_type
    assert_not_nil seeder.enzyme_sample_type
    assert_not_nil seeder.culture1
    assert_not_nil seeder.culture2
    assert_not_nil seeder.enzyme1
    assert_not_nil seeder.enzyme2
    assert_not_nil seeder.enzyme3
    assert_not_nil seeder.enzyme4

    # Check that asset-related data is populated
    assert_not_nil seeder.data_file1
    assert_not_nil seeder.data_file2
    assert_not_nil seeder.model
    assert_not_nil seeder.sop
    assert_not_nil seeder.publication
  end
end
