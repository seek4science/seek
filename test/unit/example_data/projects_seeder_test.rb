require 'test_helper'

class ProjectsSeederTest < ActiveSupport::TestCase
  def setup
    User.current_user = nil
    disable_std_output
  end

  def teardown
    User.current_user = nil
    enable_std_output
  end

  test 'seeds projects and basic setup' do
    
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
    program = result[:program].reload
    assert_equal 'Default Programme', program.title
    assert_equal 'http://www.seek4science.org', program.web_page
    assert_equal 'This is a test programme for the SEEK sandbox.', program.description
    assert_equal 'Funding H2020X01Y001', program.funding_details
    
    # Verify project attributes
    project = result[:project].reload
    assert_equal 'Default Project', project.title
    assert_equal 'A description for the default project', project.description
    assert_equal 'http://www.seek4science.org', project.web_page
    assert_equal 'http://www.wiki.org/', project.wiki_page
    assert_equal program, project.programme
    
    # Verify institution attributes
    institution = result[:institution].reload
    assert_equal 'Default Institution', institution.title
    assert_equal 'GB', institution.country
    assert_equal 'Manchester', institution.city
    
    # Verify strain attributes
    strain = result[:strain].reload
    assert_equal 'Sulfolobus solfataricus strain 98/2', strain.title
    assert_includes strain.projects, project
    
    # Verify organism attributes
    organism = result[:organism].reload
    assert_equal 'Sulfolobus solfataricus', organism.title
    assert_includes organism.projects, project
    assert_equal 'http://purl.bioontology.org/ontology/NCBITAXON/2287', organism.concept_uri
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
