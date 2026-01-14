# frozen_string_literal: true

require 'minitest/autorun'
require 'test_helper'

class SinglePagesHelperTest < ActiveSupport::TestCase
  include AuthenticatedTestHelper
  include SinglePagesHelper

  def setup
    @person = FactoryBot.create(:person)
    @project = @person.projects.first
    @investigation = FactoryBot.create(:investigation, projects: [@project], is_isa_json_compliant: true, contributor: @person)
    @study = FactoryBot.create(:isa_json_compliant_study, investigation: @investigation, contributor: @person)

    string_attr_type = FactoryBot.create(:string_sample_attribute_type)
    integer_attr_type = FactoryBot.create(:integer_sample_attribute_type)
    reg_sample_attr_type = FactoryBot.create(:sample_sample_attribute_type)
    reg_sample_mutli_attr_type = FactoryBot.create(:sample_multi_sample_attribute_type)
    reg_data_file_attr_type = FactoryBot.create(:data_file_sample_attribute_type)
    cv_attr_type = FactoryBot.create(:controlled_vocab_attribute_type)
    cv_list_attr_type = FactoryBot.create(:cv_list_attribute_type)
    strain_attr_type = FactoryBot.create(:strain_sample_attribute_type)
    sop_sample_attr_type = FactoryBot.create(:sop_sample_attribute_type)

    @cars_sample_type = FactoryBot.create(
      :sample_type,
      title: 'Cars',
      projects: [@project],
      contributor: @person,
      sample_attributes: [
        FactoryBot.build(:sample_attribute, title: 'name', sample_attribute_type: string_attr_type, required: true, is_title: true),
        FactoryBot.build(:sample_attribute, title: 'brand', sample_attribute_type: string_attr_type),
        FactoryBot.build(:sample_attribute, title: 'model', sample_attribute_type: string_attr_type),
        FactoryBot.build(:sample_attribute, title: 'race_number', sample_attribute_type: integer_attr_type),
      ]
    )

    @drivers_sample_type = FactoryBot.create(
      :sample_type,
      title: 'Drivers',
      projects: [@project],
      contributor: @person,
      sample_attributes: [
        FactoryBot.build(:sample_attribute, title: 'name', sample_attribute_type: string_attr_type, required: true, is_title: true),
        FactoryBot.build(:sample_attribute, title: 'team', sample_attribute_type: string_attr_type),
        FactoryBot.build(:sample_attribute, title: 'victories', sample_attribute_type: integer_attr_type),
        FactoryBot.build(:sample_attribute, title: 'crashes', sample_attribute_type: integer_attr_type),
        FactoryBot.build(:sample_attribute, title: 'ranking', sample_attribute_type: integer_attr_type),
      ]
    )

    race_cars.each do |car|
      sample = FactoryBot.build(:sample, title: car[:name], sample_type: @cars_sample_type, projects: [@project], contributor: @person)
      sample.set_attribute_value(:name, car[:name])
      sample.set_attribute_value(:brand, car[:brand])
      sample.set_attribute_value(:model, car[:model])
      sample.set_attribute_value(:race_number, car[:race_number])
      sample.save
    end

    drivers.each do |driver|
      sample = FactoryBot.build(:sample, title: driver[:name], sample_type: @drivers_sample_type, projects: [@project], contributor: @person)
      sample.set_attribute_value(:name, driver[:name])
      sample.set_attribute_value(:team, driver[:team])
      sample.set_attribute_value(:victories, driver[:victories])
      sample.set_attribute_value(:crashes, driver[:crashes])
      sample.set_attribute_value(:ranking, driver[:ranking])
      sample.save
    end

    sample_attributes = [
      FactoryBot.build(:sample_attribute, title: 'Title', sample_attribute_type: string_attr_type, required: true, is_title: true),
      FactoryBot.build(:sample_attribute, title: 'Driver', sample_attribute_type: reg_sample_attr_type, required: false, is_title: false, linked_sample_type: @drivers_sample_type),
      FactoryBot.build(:sample_attribute, title: 'Cars', sample_attribute_type: reg_sample_mutli_attr_type, required: false, is_title: false, linked_sample_type: @cars_sample_type),
      FactoryBot.build(:sample_attribute, title: 'Registered Data File', sample_attribute_type: reg_data_file_attr_type, required: false, is_title: false),
      FactoryBot.build(:sample_attribute, title: 'Apples Controlled Vocab', sample_attribute_type: cv_attr_type, required: false, is_title: false, sample_controlled_vocab: FactoryBot.create(:apples_sample_controlled_vocab, title: 'apples cv', key: 'apple')),
      FactoryBot.build(:sample_attribute, title: 'Topics Controlled Vocab List', sample_attribute_type: cv_list_attr_type, required: false, is_title: false, sample_controlled_vocab: FactoryBot.create(:topics_controlled_vocab, title: 'topics cv list', key: 'top')),
      FactoryBot.build(:sample_attribute, title: 'Registered Strain', sample_attribute_type: strain_attr_type, required: false, is_title: false),
      FactoryBot.build(:sample_attribute, title: 'Registered SOP', sample_attribute_type: sop_sample_attr_type, required: false, is_title: false),
    ]
    @assay_sample_type = FactoryBot.create(:sample_type, title: "Assay Sample Type", projects: [@project], contributor: @person, sample_attributes: sample_attributes)
    @assay = FactoryBot.create(:assay, study: @study, contributor: @person, sample_type: @assay_sample_type)

    organism = FactoryBot.create(:organism, title: "E. coli", projects: [@project])
    (1..3).each do |i|
      FactoryBot.create(:min_sop, title: "Assay SOP #{i}", projects: [@project], contributor: @person)
      FactoryBot.create(:data_file, title: "Data File #{i}", projects: [@project], contributor: @person)
      FactoryBot.create(:strain, title: "E. coli strain #{i}", organism: organism, projects: [@project], contributor: @person)
    end

    (1..3).each { |i| FactoryBot.create(:min_sop, assays: [@assay], title: "Assay SOP #{i}", projects: [@project], contributor: @person) }
  end

  test 'should require (excel) data validation' do
    # Title: String attributes do not require data validation
    refute requires_data_validation?(@assay_sample_type.sample_attributes.detect { |sa| sa.title == "Title" })

    # Driver: Seek Sample attributes require data validation
    assert requires_data_validation?(@assay_sample_type.sample_attributes.detect { |sa| sa.title == "Driver" })

    # Cars: Seek Sample Multi attributes do not require data validation
    refute requires_data_validation?(@assay_sample_type.sample_attributes.detect { |sa| sa.title == "Cars" })

    # Registered Data File: Seek Data File attributes require data validation
    assert requires_data_validation?(@assay_sample_type.sample_attributes.detect { |sa| sa.title == "Registered Data File" })

    # Apples Controlled Vocab: CV attributes require data validation
    assert requires_data_validation?(@assay_sample_type.sample_attributes.detect { |sa| sa.title == "Apples Controlled Vocab" })

    # Topics Controlled Vocab List: CV List attributes do not require data validation
    refute requires_data_validation?(@assay_sample_type.sample_attributes.detect { |sa| sa.title == "Topics Controlled Vocab List" })

    # Registered Strain: Seek Strain attributes require data validation
    assert requires_data_validation?(@assay_sample_type.sample_attributes.detect { |sa| sa.title == "Registered Strain" })

    # Registered SOP: Seek SOP attributes require data validation
    assert requires_data_validation?(@assay_sample_type.sample_attributes.detect { |sa| sa.title == "Registered SOP" })
  end

  test 'should ge sample values for CV attributes' do
    # Apples Controlled Vocab is of type CV
    cv_attr = @assay_sample_type.sample_attributes.detect { |sa| sa.title == "Apples Controlled Vocab" }
    apple_labels = SampleControlledVocab.find_by(title: 'apples cv').labels
    apple_values = get_values_for_cv(cv_attr)
    assert apple_values.all? { |av| apple_labels.include? av }
  end

  test 'should get sample values for Seek Sample attributes' do
    # Driver attribute is of type Seek Sample
    reg_sample_attr = @assay_sample_type.sample_attributes.detect { |sa| sa.title == "Driver" }
    reg_sample_values = get_values_for_registered_samples(reg_sample_attr).map { |sample| JSON.parse(sample) }
    driver_ids = @drivers_sample_type.samples.pluck(:id)
    assert reg_sample_values.all? { |rsv| driver_ids.include?(rsv['id']) }

    # Cars attribute is of type Seek Sample Multi
    reg_sample_mult_attr = @assay_sample_type.sample_attributes.detect { |sa| sa.title == "Cars" }
    reg_sample_multi_values = get_values_for_registered_samples(reg_sample_mult_attr).map { |sample| JSON.parse(sample) }
    car_ids = @cars_sample_type.samples.pluck(:id)
    assert reg_sample_multi_values.all? { |rsmv| car_ids.include?(rsmv['id']) }
  end

  test 'should ge sample values for Seek Data File attributes' do
    # Registered Data File attribute is of type Seek Data File
    reg_data_file_attr = @assay_sample_type.sample_attributes.detect { |sa| sa.title == "Registered Data File" }
    reg_data_file_values = get_values_for_datafiles(reg_data_file_attr).map { |rdfv| JSON.parse(rdfv) }
    data_file_ids = @project.data_files.pluck(:id)
    assert reg_data_file_values.all? { |data_file| data_file_ids.include?(data_file['id']) }
  end

  test 'should ge sample values for Seek Strain attributes' do
    # Registered Strain attribute is of type Seek Strain
    strain_attr = @assay_sample_type.sample_attributes.detect { |sa| sa.title == "Registered Strain" }
    strain_values = get_values_for_strains(strain_attr).map { |strain| JSON.parse(strain) }
    strain_ids = @project.strains.pluck(:id)
    assert strain_values.all? { |sv| strain_ids.include?(sv['id']) }
  end

  test 'should ge sample values for Seek SOP attributes' do
    # Registered SOP attribute is of type Seek SOP
    sop_attr = @assay_sample_type.sample_attributes.detect { |sa| sa.title == "Registered SOP" }
    sop_values = get_values_for_sops(sop_attr).map { |sop| JSON.parse(sop) }
    sop_ids = @assay.sops.pluck(:id)
    assert sop_values.all? { |sv| sop_ids.include?(sv['id']) }
  end

  private

  def race_cars
    [
      { model: "R8 LMS GT3", brand: "Audi", name: "Silver Arrow", race_number: 12 },
      { model: "488 GT3 Evo", brand: "Ferrari", name: "Red Fury", race_number: 27 },
      { model: "AMG GT3", brand: "Mercedes-Benz", name: "Black Panther", race_number: 44 },
      { model: "911 GT3 R", brand: "Porsche", name: "White Lightning", race_number: 91 },
      { model: "Huracán GT3 EVO", brand: "Lamborghini", name: "Green Beast", race_number: 63 },
      { model: "Supra GT500", brand: "Toyota", name: "Samurai Speed", race_number: 37 },
      { model: "M6 GT3", brand: "BMW", name: "Blue Thunder", race_number: 99 },
      { model: "Vantage GT3", brand: "Aston Martin", name: "British Bullet", race_number: 7 }
    ]
  end

  def drivers
    [
      { name: "Alex Hunter", team: "Audi Sport", victories: 15, crashes: 3, ranking: 1 },
      { name: "Marco Rossi", team: "Ferrari Racing", victories: 12, crashes: 5, ranking: 2 },
      { name: "Liam Carter", team: "Mercedes-AMG", victories: 10, crashes: 2, ranking: 3 },
      { name: "Sven Müller", team: "Porsche Motorsport", victories: 8, crashes: 4, ranking: 4 },
      { name: "Diego Alvarez", team: "Lamborghini Squadra Corse", victories: 7, crashes: 6, ranking: 5 },
      { name: "Hiro Tanaka", team: "Toyota Gazoo Racing", victories: 6, crashes: 3, ranking: 6 },
      { name: "Max Bauer", team: "BMW Motorsport", victories: 5, crashes: 7, ranking: 7 },
      { name: "Oliver Grant", team: "Aston Martin Racing", victories: 4, crashes: 2, ranking: 8 }
    ]
  end

end
