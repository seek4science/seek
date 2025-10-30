# Seeds data files, models, and SOPs
module Seek
  module ExampleData
    class DataFilesAndModelsSeeder
      def initialize(project, guest_person, guest_user, exp_assay, model_assay, seed_data_dir)
        @project = project
        @guest_person = guest_person
        @guest_user = guest_user
        @exp_assay = exp_assay
        @model_assay = model_assay
        @seed_data_dir = seed_data_dir
      end
      
      def seed
        puts "Seeding data files and models..."
        
        # Data file 1
        data_file1 = create_data_file(
          'Metabolite concentrations during reconstituted enzyme incubation',
          'The purified enzymes, PGK, GAPDH, TPI and FBPAase were incubated at 70 C en conversion of 3PG to F6P was followed.',
          'ValidationReference.xlsx',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        )
        
        relationship = RelationshipType.where(title: 'Validation data').first
        disable_authorization_checks do
          @exp_assay.associate(data_file1)
          @model_assay.associate(data_file1, relationship: relationship)
        end
        puts 'Seeded data file 1.'
        
        # Data file 2
        data_file2 = create_data_file(
          'Model simulation and Exp data for reconstituted system',
          'Experimental data for the reconstituted system are plotted together with the model prediction.',
          'combinedPlot.jpg',
          'image/jpeg'
        )
        
        disable_authorization_checks do
          @exp_assay.associate(data_file2)
          @model_assay.associate(data_file2, relationship: relationship)
        end
        puts 'Seeded data file 2.'
        
        # Model
        model = create_model
        puts 'Seeded 1 model.'
        
        # SOP
        sop = create_sop
        puts 'Seeded 1 SOP.'
        
        {
          data_file1: data_file1,
          data_file2: data_file2,
          model: model,
          sop: sop
        }
      end
      
      private
      
      def create_data_file(title, description, filename, content_type)
        data_file = DataFile.new(title: title, description: description)
        data_file.contributor = @guest_person
        data_file.projects = [@project]
        data_file.policy = Policy.create(name: 'default policy', access_type: 1)
        data_file.content_blob = ContentBlob.new(
          original_filename: filename,
          content_type: content_type
        )
        
        disable_authorization_checks { data_file.save }
        AssetsCreator.create(asset_id: data_file.id, creator_id: @guest_user.id, asset_type: data_file.class.name)
        
        # Copy file
        source_path = File.join(@seed_data_dir, filename)
        FileUtils.cp(source_path, data_file.content_blob.filepath)
        disable_authorization_checks { data_file.content_blob.save }
        
        data_file
      end
      
      def create_model
        model = Model.new(
          title: 'Mathematical model for the combined four enzyme system',
          description: 'The PGK, GAPDH, TPI and FBPAase were modelled together using the individual rate equations. Closed system.'
        )
        model.model_format = ModelFormat.find_by_title('SBML')
        model.contributor = @guest_person
        model.projects = [@project]
        model.assays = [@model_assay]
        model.policy = Policy.create(name: 'default policy', access_type: 1)
        model.model_type = ModelType.where(title: 'Ordinary differential equations (ODE)').first
        model.model_format = ModelFormat.where(title: 'SBML').first
        model.recommended_environment = RecommendedModelEnvironment.where(title: 'JWS Online').first
        model.organism = Organism.where(title: 'Sulfolobus solfataricus').first
        
        # Create content blobs
        blob_files = [
          'ssolfGluconeogenesisOpenAnn.dat',
          'ssolfGluconeogenesisOpenAnn.xml',
          'ssolfGluconeogenesisOpenAnn.xml',
          'ssolfGluconeogenesisAnn.xml',
          'ssolfGluconeogenesisClosed.xml',
          'ssolfGluconeogenesis.xml'
        ]
        
        content_blobs = blob_files.map do |filename|
          content_type = filename.end_with?('.dat') ? 'text/x-uuencode' : 'text/xml'
          ContentBlob.new(original_filename: filename, content_type: content_type)
        end
        
        model.content_blobs = content_blobs
        disable_authorization_checks { model.save }
        AssetsCreator.create(asset_id: model.id, creator_id: @guest_person.id, asset_type: model.class.name)
        
        # Copy files
        model.content_blobs.each do |blob|
          source_path = File.join(@seed_data_dir, blob.original_filename)
          FileUtils.cp(source_path, blob.filepath)
          blob.save
        end
        
        model
      end
      
      def create_sop
        sop = Sop.new(
          title: 'Reconstituted Enzyme System Protocol',
          description: 'Standard operating procedure for reconstituting the gluconeogenic enzyme system from Sulfolobus solfataricus to study metabolic pathway efficiency at high temperatures.'
        )
        sop.contributor = @guest_person
        sop.projects = [@project]
        sop.assays = [@exp_assay, @model_assay]
        sop.policy = Policy.create(name: 'default policy', access_type: 1)
        sop.content_blob = ContentBlob.new(
          original_filename: 'test_sop.txt',
          content_type: 'text'
        )
        
        AssetsCreator.create(asset_id: sop.id, creator_id: @guest_person.id, asset_type: sop.class.name)
        
        source_path = File.join(@seed_data_dir, sop.content_blob.original_filename)
        FileUtils.cp(source_path, sop.content_blob.filepath)
        
        disable_authorization_checks { sop.save! }
        sop.annotate_with(['protocol', 'enzymology', 'thermophile'], 'tag', @guest_person)
        
        sop
      end
    end
  end
end
