# Seeds publications, presentations and events
module Seek
  module ExampleData
    class PublicationsSeeder
      def initialize(project, guest_person, guest_user, exp_assay, model_assay, seed_data_dir)
        @project = project
        @guest_person = guest_person
        @guest_user = guest_user
        @exp_assay = exp_assay
        @model_assay = model_assay
        @seed_data_dir = seed_data_dir
      end
      
      def seed
        puts "Seeding publications and presentations..."
        
        # Publication
        publication = create_publication
        puts 'Seeded 1 publication.'
        
        # Presentation
        presentation = create_presentation
        puts 'Seeded 1 presentation.'
        
        # Event
        event = create_event
        puts 'Seeded 1 event.'
        
        {
          publication: publication,
          presentation: presentation,
          event: event
        }
      end
      
      private
      
      def create_publication
        publication = Publication.new(
          publication_type_id: PublicationType.where(title: "Journal").first.id,
          pubmed_id: '23865479',
          title: 'Intermediate instability at high temperature leads to low pathway efficiency for an in vitro reconstituted system of gluconeogenesis in Sulfolobus solfataricus',
          abstract: "Four enzymes of the gluconeogenic pathway in Sulfolobus solfataricus were purified and kinetically characterized. The enzymes were reconstituted in vitro to quantify the contribution of temperature instability of the pathway intermediates to carbon loss from the system. The reconstituted system, consisting of phosphoglycerate kinase, glyceraldehyde 3-phosphate dehydrogenase, triose phosphate isomerase and the fructose 1,6-bisphosphate aldolase/phosphatase, maintained a constant consumption rate of 3-phosphoglycerate and production of fructose 6-phosphate over a 1-h period. Cofactors ATP and NADPH were regenerated via pyruvate kinase and glucose dehydrogenase. A mathematical model was constructed on the basis of the kinetics of the purified enzymes and the measured half-life times of the pathway intermediates. The model quantitatively predicted the system fluxes and metabolite concentrations. Relative enzyme concentrations were chosen such that half the carbon in the system was lost due to degradation of the thermolabile intermediates dihydroxyacetone phosphate, glyceraldehyde 3-phosphate and 1,3-bisphosphoglycerate, indicating that intermediate instability at high temperature can significantly affect pathway efficiency.",
          published_date: '2015',
          journal: 'FEBS J'
        )
        
        publication.contributor = @guest_person
        publication.projects << @project
        publication.build_policy(name: 'default policy', access_type: 1)
        publication.published_date = Date.today.to_s
        
        # Build publication authors
        authors = [
          { first_name: 'T.', last_name: 'Kouril', author_index: 1 },
          { first_name: 'D.', last_name: 'Esser', author_index: 2 },
          { first_name: 'J.', last_name: 'Kort', author_index: 3 },
          { first_name: 'H. V.', last_name: 'Westerhoff', author_index: 4 },
          { first_name: 'B.', last_name: 'Siebers', author_index: 5 },
          { first_name: 'J.', last_name: 'Snoep', author_index: 6 }
        ]
        
        publication.citation = "Kouril, T. et al. Intermediate instability at high temperature leads to low pathway efficiency for an in vitro reconstituted system of gluconeogenesis in Sulfolobus solfataricus. FEBS J. 2015;687:100-108."
        
        authors.each do |author_attrs|
          publication.publication_authors.build(author_attrs)
        end
        
        disable_authorization_checks do
          publication.save!
          publication.associate(@exp_assay)
          publication.associate(@model_assay)
        end
        
        AssetsCreator.create(asset_id: publication.id, creator_id: @guest_person.id, asset_type: publication.class.name)
        
        publication
      end
      
      def create_presentation
        presentation = Presentation.new(
          title: 'Intermediate instability at high temperature leads to low pathway efficiency for an in vitro reconstituted system of gluconeogenesis in Sulfolobus solfataricus',
          description: "Four enzymes of the gluconeogenic pathway in Sulfolobus solfataricus were purified and kinetically characterized. The enzymes were reconstituted in vitro to quantify the contribution of temperature instability of the pathway intermediates to carbon loss from the system. The reconstituted system, consisting of phosphoglycerate kinase, glyceraldehyde 3-phosphate dehydrogenase, triose phosphate isomerase and the fructose 1,6-bisphosphate aldolase/phosphatase, maintained a constant consumption rate of 3-phosphoglycerate and production of"
        )
        presentation.projects = [@project]
        presentation.contributor = @guest_person
        presentation.policy = Policy.create(name: 'default policy', access_type: 1)
        presentation.content_blob = ContentBlob.new(
          original_filename: 'presentation.pptx',
          content_type: 'application/vnd.openxmlformats-officedocument.presentationml.presentation'
        )
        
        AssetsCreator.create(asset_id: presentation.id, creator_id: @guest_person.id, asset_type: presentation.class.name)
        
        source_path = File.join(@seed_data_dir, presentation.content_blob.original_filename)
        FileUtils.cp(source_path, presentation.content_blob.filepath)
        
        presentation.version = 1
        presentation.save!
        
        presentation
      end
      
      def create_event
        event = Event.new(
          title: 'Event for publication',
          description: 'Event for publication',
          start_date: Date.today,
          end_date: Date.today + 1.day
        )
        event.projects = [@project]
        event.contributor = @guest_person
        event.policy = Policy.create(name: 'default policy', access_type: 1)
        event.city = 'London'
        event.country = 'United Kingdom'
        event.address = 'Dunmore Terrace 123'
        event.save!
        
        event
      end
    end
  end
end
