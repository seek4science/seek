# Seeds basic project structure - programme, project, institution, workgroups, strains, organisms
module Seek
  module ExampleData
    class ProjectsSeeder
      def seed
        puts "Seeding projects and basic setup..."
        
        # Programme
        program = Programme.find_or_initialize_by(title: 'Default Programme')
        program.update(
          web_page: 'http://www.seek4science.org',
          funding_details: 'Funding H2020X01Y001',
          description: 'This is a test programme for the SEEK sandbox.'
        )
        disable_authorization_checks{ program.save! }
        
        # Project
        project = Project.find_or_initialize_by(title: 'Default Project')
        project.update(
          programme_id: program.id,
          description: 'A description for the default project',
          web_page: 'https://www.seek4science.org',
          wiki_page: 'https://www.wiki.org'
        )
        disable_authorization_checks{ project.save! }
        
        # Institution
        institution = Institution.find_or_initialize_by(title: 'Default Institution')
        institution.update(
          country: 'United Kingdom',
          city: 'Manchester',
          address: '10 Downing Street'
        )

        disable_authorization_checks{ institution.save! }
        
        # Workgroup
        workgroup = WorkGroup.where(project_id: project.id, institution_id: institution.id).first_or_create

        disable_authorization_checks{ workgroup.save! }
        
        # Strain
        strain = Strain.where(title: 'Sulfolobus solfataricus strain 98/2').first_or_create
        strain.projects = [project]
        strain.policy = Policy.create(name: 'default policy', access_type: 1)
        strain.organism = Organism.where(title: 'Sulfolobus solfataricus').first_or_create
        strain.provider_name = 'BacDive'
        strain.provider_id = '123456789'
        strain.synonym = '98/2'
        strain.comment = 'This is a test strain.'
        disable_authorization_checks do
          strain.save!
        end
        puts 'Seeded 1 strain.'
        
        # Organism
        organism = Organism.where(title: 'Sulfolobus solfataricus').first_or_create
        organism.projects = [project]
        organism.concept_uri = '2287'
        organism.strains = [strain]
        disable_authorization_checks do
          organism.save!
        end
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
