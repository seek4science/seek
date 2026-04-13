# Seeds sample types and samples
module Seek
  module ExampleData
    class SamplesSeeder
      def initialize(project, guest_person, exp_assay, study)
        @project = project
        @guest_person = guest_person
        @exp_assay = exp_assay
        @study = study
      end
      
      def seed
        puts "Seeding samples..."
        
        # Get sample attribute types
        string_attr_type = SampleAttributeType.where(title: 'String').first_or_create(base_type: 'String')
        float_attr_type = SampleAttributeType.where(title: 'Real number').first_or_create(base_type: 'Float')
        integer_attr_type = SampleAttributeType.where(title: 'Integer').first_or_create(base_type: 'Integer')
        boolean_attr_type = SampleAttributeType.where(title: 'Boolean').first_or_create(base_type: 'Boolean')
        
        # Create bacterial culture sample type
        culture_sample_type = create_culture_sample_type(string_attr_type, float_attr_type, boolean_attr_type)
        
        # Create enzyme sample type
        enzyme_sample_type = create_enzyme_sample_type(string_attr_type, float_attr_type, integer_attr_type)
        
        # Create culture samples
        culture1 = create_culture_sample('S. solfataricus Culture #1', culture_sample_type, 
                                        'Sulfolobus solfataricus strain 98/2', 80.0, 500.0, 2.5, true)
        culture2 = create_culture_sample('S. solfataricus Culture #2', culture_sample_type,
                                        'Sulfolobus solfataricus strain 98/2', 75.0, 1000.0, 2.8, false)
        
        # Create enzyme samples
        enzyme1 = create_enzyme_sample('Phosphoglycerate Kinase', enzyme_sample_type,
                                      'EC 2.7.2.3', 2.5, 125.0, -20, 4)
        enzyme2 = create_enzyme_sample('Glyceraldehyde-3-phosphate Dehydrogenase', enzyme_sample_type,
                                      'EC 1.2.1.12', 1.8, 89.3, -20, 3)
        enzyme3 = create_enzyme_sample('Triose Phosphate Isomerase', enzyme_sample_type,
                                      'EC 5.3.1.1', 3.2, 210.5, -20, 2)
        enzyme4 = create_enzyme_sample('Fructose-1,6-bisphosphate Aldolase/Phosphatase', enzyme_sample_type,
                                      'EC 4.1.2.13', 1.5, 67.8, -20, 5)
        
        # Associate samples with experimental assay
        disable_authorization_checks do
          @exp_assay.samples = [culture1, culture2, enzyme1, enzyme2, enzyme3, enzyme4]
          @exp_assay.save!
        end
        
        # Associate sample types with study
        disable_authorization_checks do
          @study.sample_types = [culture_sample_type, enzyme_sample_type]
          @study.save!
        end
        
        puts 'Seeded sample types and samples - 2 sample types with 6 total samples.'
        
        {
          culture_sample_type: culture_sample_type,
          enzyme_sample_type: enzyme_sample_type,
          culture1: culture1,
          culture2: culture2,
          enzyme1: enzyme1,
          enzyme2: enzyme2,
          enzyme3: enzyme3,
          enzyme4: enzyme4
        }
      end
      
      private
      
      def create_culture_sample_type(string_attr_type, float_attr_type, boolean_attr_type)
        sample_type = SampleType.new(
          title: 'Bacterial Culture',
          description: 'Sample type for bacterial culture experiments related to thermophile studies'
        )
        sample_type.projects = [@project]
        sample_type.contributor = @guest_person
        sample_type.policy = Policy.create(name: 'default policy', access_type: 1)
        
        sample_type.sample_attributes.build(
          title: 'Culture Name',
          sample_attribute_type: string_attr_type,
          required: true,
          is_title: true,
          description: 'A unique name for the bacterial culture'
        )
        
        sample_type.sample_attributes.build(
          title: 'Strain Used',
          sample_attribute_type: string_attr_type,
          required: true,
          description: 'The bacterial strain used for this culture'
        )
        
        sample_type.sample_attributes.build(
          title: 'Growth Temperature',
          sample_attribute_type: float_attr_type,
          unit: Unit.find_by_symbol('°C'),
          required: true,
          description: 'Temperature at which the culture was grown'
        )
        
        sample_type.sample_attributes.build(
          title: 'Culture Volume',
          sample_attribute_type: float_attr_type,
          unit: Unit.find_by_symbol('mL'),
          required: false,
          description: 'Volume of the bacterial culture'
        )
        
        sample_type.sample_attributes.build(
          title: 'pH',
          sample_attribute_type: float_attr_type,
          required: false,
          description: 'pH of the culture medium'
        )
        
        sample_type.sample_attributes.build(
          title: 'Growth Phase Complete',
          sample_attribute_type: boolean_attr_type,
          required: false,
          description: 'Whether the culture has reached stationary phase'
        )
        
        disable_authorization_checks { sample_type.save! }
        sample_type.annotate_with(['bacterial culture', 'thermophile', 'microbiology'], 'tag', @guest_person)
        puts 'Seeded bacterial culture sample type.'
        
        sample_type
      end
      
      def create_enzyme_sample_type(string_attr_type, float_attr_type, integer_attr_type)
        sample_type = SampleType.new(
          title: 'Enzyme Preparation',
          description: 'Sample type for purified enzyme preparations used in reconstituted systems'
        )
        sample_type.projects = [@project]
        sample_type.contributor = @guest_person
        sample_type.policy = Policy.create(name: 'default policy', access_type: 1)
        
        sample_type.sample_attributes.build(
          title: 'Enzyme Name',
          sample_attribute_type: string_attr_type,
          required: true,
          is_title: true
        )
        
        sample_type.sample_attributes.build(
          title: 'EC Number',
          sample_attribute_type: string_attr_type,
          required: false,
          description: 'Enzyme Commission number',
          pid: 'http://purl.uniprot.org/core/enzyme'
        )
        
        sample_type.sample_attributes.build(
          title: 'Concentration',
          sample_attribute_type: float_attr_type,
          unit: Unit.find_by_symbol('mg/mL'),
          required: true,
          description: 'Protein concentration of the enzyme preparation'
        )
        
        sample_type.sample_attributes.build(
          title: 'Specific Activity',
          sample_attribute_type: float_attr_type,
          unit: Unit.find_by_symbol('U/mg'),
          required: false,
          description: 'Specific enzymatic activity'
        )
        
        sample_type.sample_attributes.build(
          title: 'Storage Temperature',
          sample_attribute_type: integer_attr_type,
          unit: Unit.find_by_symbol('°C'),
          required: false,
          description: 'Temperature for enzyme storage'
        )
        
        sample_type.sample_attributes.build(
          title: 'Purification Steps',
          sample_attribute_type: integer_attr_type,
          required: false,
          description: 'Number of purification steps performed'
        )
        
        disable_authorization_checks { sample_type.save! }
        sample_type.annotate_with(['enzyme', 'protein', 'purification'], 'tag', @guest_person)
        puts 'Seeded enzyme preparation sample type.'
        
        sample_type
      end
      
      def create_culture_sample(name, sample_type, strain, temp, volume, ph, complete)
        sample = Sample.new(title: name)
        sample.sample_type = sample_type
        sample.projects = [@project]
        sample.contributor = @guest_person
        sample.policy = Policy.create(name: 'default policy', access_type: 1)
        sample.set_attribute_value('Culture Name', name)
        sample.set_attribute_value('Strain Used', strain)
        sample.set_attribute_value('Growth Temperature', temp)
        sample.set_attribute_value('Culture Volume', volume)
        sample.set_attribute_value('pH', ph)
        sample.set_attribute_value('Growth Phase Complete', complete)
        disable_authorization_checks { sample.save! }
        puts "Seeded bacterial culture sample: #{name}."
        sample
      end
      
      def create_enzyme_sample(name, sample_type, ec_number, concentration, activity, storage_temp, purification_steps)
        sample = Sample.new(title: name)
        sample.sample_type = sample_type
        sample.projects = [@project]
        sample.contributor = @guest_person
        sample.policy = Policy.create(name: 'default policy', access_type: 1)
        sample.set_attribute_value('Enzyme Name', name)
        sample.set_attribute_value('EC Number', ec_number)
        sample.set_attribute_value('Concentration', concentration)
        sample.set_attribute_value('Specific Activity', activity)
        sample.set_attribute_value('Storage Temperature', storage_temp)
        sample.set_attribute_value('Purification Steps', purification_steps)
        disable_authorization_checks { sample.save! }
        puts "Seeded enzyme sample: #{name}."
        sample
      end
    end
  end
end
