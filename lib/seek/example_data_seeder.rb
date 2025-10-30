# Main class to orchestrate seeding example data
module Seek
  class ExampleDataSeeder
    attr_reader :project, :institution, :workgroup, :program, :strain, :organism
    attr_reader :admin_user, :admin_person, :guest_user, :guest_person
    attr_reader :investigation, :study, :observation_unit, :exp_assay, :model_assay, :assay_stream
    attr_reader :culture_sample_type, :enzyme_sample_type
    attr_reader :culture1, :culture2, :enzyme1, :enzyme2, :enzyme3, :enzyme4
    attr_reader :data_file1, :data_file2, :model, :sop
    attr_reader :publication, :presentation, :event

    def initialize
      @seed_data_dir = File.join(Rails.root, 'db', 'seeds', 'example_data')
    end

    # Main entry point to seed all example data
    def seed_all
      puts "Starting example data seeding..."
      
      seed_projects_and_basic_setup
      seed_users
      seed_isa_structure
      seed_samples
      seed_data_files_and_models
      seed_publications_and_presentations
      seed_configuration
      
      puts "Example data seeding completed!"
    end

    private

    def seed_projects_and_basic_setup
      seeder = Seek::ExampleData::ProjectsSeeder.new
      result = seeder.seed
      
      @program = result[:program]
      @project = result[:project]
      @institution = result[:institution]
      @workgroup = result[:workgroup]
      @strain = result[:strain]
      @organism = result[:organism]
    end

    def seed_users
      seeder = Seek::ExampleData::UsersSeeder.new(@workgroup, @project, @institution)
      result = seeder.seed
      
      @admin_user = result[:admin_user]
      @admin_person = result[:admin_person]
      @guest_user = result[:guest_user]
      @guest_person = result[:guest_person]
    end

    def seed_isa_structure
      seeder = Seek::ExampleData::ISAStructureSeeder.new(@project, @guest_person, @organism)
      result = seeder.seed
      
      @investigation = result[:investigation]
      @study = result[:study]
      @observation_unit = result[:observation_unit]
      @exp_assay = result[:exp_assay]
      @model_assay = result[:model_assay]
      @assay_stream = result[:assay_stream]
    end

    def seed_samples
      seeder = Seek::ExampleData::SamplesSeeder.new(@project, @guest_person, @exp_assay, @study)
      result = seeder.seed
      
      @culture_sample_type = result[:culture_sample_type]
      @enzyme_sample_type = result[:enzyme_sample_type]
      @culture1 = result[:culture1]
      @culture2 = result[:culture2]
      @enzyme1 = result[:enzyme1]
      @enzyme2 = result[:enzyme2]
      @enzyme3 = result[:enzyme3]
      @enzyme4 = result[:enzyme4]
    end

    def seed_data_files_and_models
      seeder = Seek::ExampleData::DataFilesAndModelsSeeder.new(
        @project, @guest_person, @guest_user, @exp_assay, @model_assay, @seed_data_dir
      )
      result = seeder.seed
      
      @data_file1 = result[:data_file1]
      @data_file2 = result[:data_file2]
      @model = result[:model]
      @sop = result[:sop]
    end

    def seed_publications_and_presentations
      seeder = Seek::ExampleData::PublicationsSeeder.new(
        @project, @guest_person, @guest_user, @exp_assay, @model_assay, @seed_data_dir
      )
      result = seeder.seed
      
      @publication = result[:publication]
      @presentation = result[:presentation]
      @event = result[:event]
    end

    def seed_configuration
      seeder = Seek::ExampleData::ConfigurationSeeder.new(
        @program, @project, @investigation, @study, @exp_assay, @model_assay,
        @data_file1, @data_file2, @model, @publication,
        @guest_user, @guest_person, @admin_person
      )
      seeder.seed
    end
  end
end
