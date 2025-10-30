# Seeds basic project structure - programme, project, institution, workgroups, strains, organisms
module Seek
  module ExampleData
    class ProjectsSeeder
      def seed
        puts "Seeding projects and basic setup..."
        
        # Programme
        program = Programme.where(title: 'Default Programme').first_or_create(
          web_page: 'http://www.seek4science.org',
          funding_details: 'Funding H2020X01Y001',
          description: 'This is a test programme for the SEEK sandbox.'
        )
        
        # Project
        project = Project.where(title: 'Default Project').first_or_create(
          programme_id: program.id,
          description: 'A description for the default project'
        )
        
        # Institution
        institution = Institution.where(title: 'Default Institution').first_or_create(
          country: 'United Kingdom'
        )
        
        # Workgroup
        workgroup = WorkGroup.where(project_id: project.id, institution_id: institution.id).first_or_create
        
        # Strain
        strain = Strain.where(title: 'Sulfolobus solfataricus strain 98/2').first_or_create
        strain.projects = [project]
        strain.policy = Policy.create(name: 'default policy', access_type: 1)
        strain.organism = Organism.where(title: 'Sulfolobus solfataricus').first_or_create
        strain.provider_name = 'BacDive'
        strain.provider_id = '123456789'
        strain.synonym = '98/2'
        strain.comment = 'This is a test strain.'
        strain.save!
        puts 'Seeded 1 strain.'
        
        # Organism
        organism = Organism.where(title: 'Sulfolobus solfataricus').first_or_create
        organism.projects = [project]
        organism.strains = [strain]
        organism.save!
        puts 'Seeded 1 organism.'
        
        {
          program: program,
          project: project,
          institution: institution,
          workgroup: workgroup,
          strain: strain,
          organism: organism
        }
      end
    end
  end
end
