require 'test_helper'

class ProjectsSeederTest < ActiveSupport::TestCase
  def setup
    User.current_user = nil
  end

  def teardown
    User.current_user = nil
  end

  test 'seeds projects and basic setup' do
    initial_program_count = Programme.count
    initial_project_count = Project.count
    initial_institution_count = Institution.count
    initial_strain_count = Strain.count
    initial_organism_count = Organism.count
    
    seeder = Seek::ExampleData::ProjectsSeeder.new
    result = seeder.seed
    
    # Check that result hash has expected keys
    assert_includes result.keys, :program
    assert_includes result.keys, :project
    assert_includes result.keys, :institution
    assert_includes result.keys, :workgroup
    assert_includes result.keys, :strain
    assert_includes result.keys, :organism
    
    # Check that objects were created
    assert_not_nil result[:program]
    assert_not_nil result[:project]
    assert_not_nil result[:institution]
    assert_not_nil result[:workgroup]
    assert_not_nil result[:strain]
    assert_not_nil result[:organism]
    
    # Verify program attributes
    program = result[:program]
    assert_equal 'Default Programme', program.title
    assert_equal 'http://www.seek4science.org', program.web_page
    
    # Verify project attributes
    project = result[:project]
    assert_equal 'Default Project', project.title
    assert_equal program.id, project.programme_id
    
    # Verify institution attributes
    institution = result[:institution]
    assert_equal 'Default Institution', institution.title
    assert_equal 'United Kingdom', institution.country
    
    # Verify strain attributes
    strain = result[:strain]
    assert_equal 'Sulfolobus solfataricus strain 98/2', strain.title
    assert_includes strain.projects, project
    
    # Verify organism attributes
    organism = result[:organism]
    assert_equal 'Sulfolobus solfataricus', organism.title
    assert_includes organism.projects, project
    assert_includes organism.strains, strain
  end

  test 'is idempotent - can run multiple times' do
    seeder = Seek::ExampleData::ProjectsSeeder.new
    
    # Run once
    result1 = seeder.seed
    count_after_first = Programme.count
    
    # Run again
    result2 = seeder.seed
    count_after_second = Programme.count
    
    # Should not create duplicates
    assert_equal count_after_first, count_after_second
    assert_equal result1[:program].id, result2[:program].id
    assert_equal result1[:project].id, result2[:project].id
  end
end
