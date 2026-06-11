# frozen_string_literal: true

module SinglePageTestUtils
  def setup_test_data
    id_label = "#{Seek::Config.instance_name} id"
    person = @member.person
    institution = FactoryBot.create(:institution, title: 'Legion Of Doooooooooom', country: 'AQ')
    project = FactoryBot.create(:project, id: 10_000)
    person.add_to_project_and_institution(project, institution)
    investigation = FactoryBot.create(:investigation, id: 10_000, is_isa_json_compliant: true, projects: [project], contributor: person)
    study = FactoryBot.create(:study, id: 10_001, investigation: investigation, contributor: person)
    assay = FactoryBot.create(:assay, id: 10_002, study:, contributor: person)

    source_sample_type_template = FactoryBot.create(:isa_source_template, id: 10_006)
    source_sample_type = FactoryBot.create(:isa_source_sample_type,
                                           id: 10_003,
                                           contributor: person,
                                           project_ids: [project.id],
                                           isa_template: source_sample_type_template,
                                           studies: [study])

    sample_collection_sample_type_template = FactoryBot.create(:isa_sample_collection_template, id: 10_007)
    sample_collection_sample_type = FactoryBot.create(:isa_sample_collection_sample_type,
                                                      id: 10_004,
                                                      contributor: person,
                                                      project_ids: [project.id],
                                                      isa_template: sample_collection_sample_type_template,
                                                      studies: [study],
                                                      linked_sample_type: source_sample_type)

    assay_sample_type_template = FactoryBot.create(:isa_assay_material_template, id: 10_008)
    assay_sample_type = FactoryBot.create(:isa_assay_material_sample_type,
                                          id: 10_005,
                                          contributor: person,
                                          isa_template: assay_sample_type_template,
                                          projects: [project],
                                          studies: [study],
                                          linked_sample_type: sample_collection_sample_type)

    sources = (1..5).map do |n|
      FactoryBot.create(
        :sample,
        id: 10_010 + n,
        title: "source_#{n}",
        sample_type: source_sample_type,
        project_ids: [project.id],
        contributor: person,
        data: {
          'Source Name': "Source #{n}",
          'Source Characteristic 1': 'Source Characteristic 1',
          'Source Characteristic 2':
            source_sample_type
              .sample_attributes
              .find_by_title('Source Characteristic 2')
              .sample_controlled_vocab
              .sample_controlled_vocab_terms
              .first
              .label
        }
      )
    end

    study_samples = (1..4).map do |n|
      FactoryBot.create(
        :sample,
        id: 10_020 + n,
        title: "Sample collection #{n}",
        sample_type: sample_collection_sample_type,
        project_ids: [project.id],
        contributor: person,
        data: {
          Input: [sources[n - 1].id, sources[n].id],
          'sample collection': 'sample collection',
          'sample collection parameter value 1': 'sample collection parameter value 1',
          'Sample Name': "sample nr. #{n}",
          'sample characteristic 1': 'sample characteristic 1'
        }
      )
    end

    assay_samples = (1..3).map do |n|
      FactoryBot.create(
        :sample,
        id: 10_030 + n,
        title: "Assay Sample #{n}",
        sample_type: assay_sample_type,
        project_ids: [project.id],
        contributor: person,
        data: {
          Input: [study_samples[n - 1].id, study_samples[n].id],
          'Protocol Assay 1': 'How to make concentrated dark matter',
          'Assay 1 parameter value 1': 'Assay 1 parameter value 1',
          'Extract Name': "Extract nr. #{n}",
          'other material characteristic 1': 'other material characteristic 1'
        }
      )
    end

    {
      "id_label": id_label,
      "person": person,
      "project": project,
      "investigation": investigation,
      "study": study,
      "assay": assay,
      "source_sample_type": source_sample_type,
      "sample_collection_sample_type": sample_collection_sample_type,
      "assay_sample_type": assay_sample_type,
      "sources": sources,
      "study_samples": study_samples,
      "assay_samples": assay_samples
    }
  end

  def car_catalogue(project, person)
    sample_catalogue_cars = FactoryBot.build(:sample_type,
                                             title: "Sample Catalogue Cars",
                                             projects: [project],
                                             contributor: person
    )
    sample_catalogue_cars.sample_attributes << [
      FactoryBot.create(:any_string_sample_attribute, title: "Car name", sample_type: sample_catalogue_cars, is_title: true),
      FactoryBot.create(:any_string_sample_attribute, title: "Brand", sample_type: sample_catalogue_cars),
      FactoryBot.create(:any_string_sample_attribute, title: "Model", sample_type: sample_catalogue_cars),
    ]
    sample_catalogue_cars.save
    names = [
      "Herbie",
      "Ecto-1",
      "K.I.T.T.",
      "General Lee",
      "DeLorean Time Machine"
    ]
    brands = [
      "Volkswagen",
      "Cadillac",
      "Pontiac",
      "Dodge",
      "DeLorean Motor Company"
    ]
    models = [
      "Beetle",
      "Miller-Meteor",
      "Firebird Trans Am",
      "Charger",
      "DMC-12"
    ]
    _cars = (1..5).map do |n|
      FactoryBot.create(:sample,
                        id: 10_040 + n,
                        title: names[n-1],
                        sample_type: sample_catalogue_cars,
                        project_ids: [project.id],
                        contributor: person,
                        data: {
                          'Car name': names[n-1],
                          Brand: brands[n-1],
                          Model: models[n-1]
                        }
      )
    end
    sample_catalogue_cars.reload
  end

  def flower_names(project, person)
    sample_catalogue_flower_names = FactoryBot.build(:sample_type,
                                                     title: "Sample Catalogue Flowers",
                                                     projects: [project],
                                                     contributor: person
    )

    sample_catalogue_flower_names.sample_attributes << [
      FactoryBot.create(:any_string_sample_attribute, title: "Human name", sample_type: sample_catalogue_flower_names, is_title: true),
      FactoryBot.create(:any_string_sample_attribute, title: "Scientific Name", sample_type: sample_catalogue_flower_names),
      FactoryBot.create(:any_string_sample_attribute, title: "Trivial Name", sample_type: sample_catalogue_flower_names),
    ]
    sample_catalogue_flower_names.save
    human_names = %w[Rosalind Sonny Daisy Lavanda Daffy]
    scientific_names = ["Rosa indica", "Helianthus annuus", "Bellis perennis", "Lavandula", "Narcissus pseudonarcissus"]
    trivial_names = ["Rose", "Sunflower", "English Daisy", "Lavender", "Wild Daffodil"]
    _flowers = (1..5).map do |n|
      FactoryBot.create(:sample,
                        id: 10_050 + n,
                        title: human_names[n - 1],
                        sample_type: sample_catalogue_flower_names,
                        project_ids: [project.id],
                        contributor: person,
                        data: {
                          'Human name': human_names[n - 1],
                          'Scientific Name': scientific_names[n-1],
                          'Trivial Name': trivial_names[n-1]
                        }
      )
    end
    sample_catalogue_flower_names.reload
  end

  def bacteria_strains(project, person)
    organism = FactoryBot.create(:organism, title: "Bacteriaceae", projects: [project])
    bacteria_names = [
      "Escherichia coli",
      "Streptococcus pyogenes",
      "Staphylococcus aureus",
      "Streptococcus pneumoniae",
      "Clostridioides difficile"
    ]

    (1..5).map do |n|
      FactoryBot.create(:strain, id: 10_060 + n, title: bacteria_names[n-1], organism: organism, projects: [project], contributor: person)
    end
  end

  def create_data_files(project, person)
    file_types = [
      "Comma-Separated Values",
      "JavaScript Object Notation",
      "Extensible Markup Language",
      "Apache Parquet",
      "Portable Document Format"
    ]
    (1..5).map do |n|
      FactoryBot.create(:min_data_file, id: 10_070 + n, title: "My #{file_types[n-1]} file", projects: [project], contributor: person)
    end
  end

  def create_sops(project, person)
    lab_protocols = [
      "Standard Operating Procedure for High-Performance Liquid Chromatography (HPLC) Analysis",
      "Protocol for DNA Isolation and Purification Using the CTAB Method",
      "Polymerase Chain Reaction (PCR) Program for Target Sequence Amplification",
      "Protocol for Protein Extraction and SDS-PAGE Analysis",
      "Standard Procedure for Chemical Spill Response and Hazardous Waste Disposal"
    ]

    (1..5).map do |n|
      FactoryBot.create(:sop, id: 10_080 + n, title: lab_protocols[n-1], projects: [project], contributor: person)
    end
  end
end
