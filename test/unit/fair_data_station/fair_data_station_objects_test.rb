require 'test_helper'

# test the objects that represent Inv, Study, Obs Unit, Sample and Assay
class FairDataStationObjectsTest < ActiveSupport::TestCase

  test 'get annotation details' do
    path = "#{Rails.root}/test/fixtures/files/fair_data_station/seek-fair-data-station-test-case.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first

    det = inv.annotation_details('http://fairbydesign.nl/ontology/date_of_birth')
    assert_equal 'date of birth', det.label
    assert_equal 'Date of birth of subject the sample was derived from.', det.description
    assert_equal 'http://fairbydesign.nl/ontology/date_of_birth', det.property_id
    assert_equal '.+', det.pattern
    assert_equal false, det.required

    det = inv.annotation_details('http://gbol.life/0.1/scientificName')
    assert_equal 'scientific name', det.label
    assert_equal 'Name of the organism', det.description
    assert_equal 'http://gbol.life/0.1/scientificName', det.property_id
    assert_equal '.*', det.pattern
    assert_equal true, det.required

    # has less complete Property descriptions
    path = "#{Rails.root}/test/fixtures/files/fair_data_station/demo.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first
    det = inv.annotation_details('http://fairbydesign.nl/ontology/center_project_name')
    assert_equal 'center project name', det.label
    assert_equal '', det.description
    assert_equal 'http://fairbydesign.nl/ontology/center_project_name', det.property_id
    assert_equal '.+', det.pattern
    assert_equal false, det.required

    # packageName not even defined, so will resolve label from fragment or path
    det = inv.annotation_details('http://fairbydesign.nl/ontology/packageName')
    assert_equal 'package name', det.label
    assert_equal '', det.description
    assert_equal 'http://fairbydesign.nl/ontology/packageName', det.property_id
    assert_equal '.*', det.pattern
    assert_equal false, det.required
    det = inv.annotation_details('http://fairbydesign.nl/ontology#packageName')
    assert_equal 'package name', det.label
    assert_equal '', det.description
    assert_equal 'http://fairbydesign.nl/ontology#packageName', det.property_id
    assert_equal '.*', det.pattern
    assert_equal false, det.required
  end

  test 'additional_metadata_annotation_details' do
    path = "#{Rails.root}/test/fixtures/files/fair_data_station/seek-fair-data-station-test-case.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first
    study = inv.studies.first
    details = study.additional_metadata_annotation_details
    assert_equal 3, details.count
    assert_equal ['end date of study', 'experimental site name', 'start date of study'], details.collect(&:label).sort

    path = "#{Rails.root}/test/fixtures/files/fair_data_station/indpensim.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first
    obs_unit = inv.studies.first.observation_units.first
    details = obs_unit.additional_metadata_annotation_details
    assert_equal 5, details.count
    assert_equal ['brand', 'fermentation', 'ncbi taxonomy id', 'scientific name', 'volume'],
                 details.collect(&:label).sort
  end

  test 'all_additional_potential_annotations_details' do
    path = "#{Rails.root}/test/fixtures/files/fair_data_station/seek-fair-data-station-test-case-irregular.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first
    study = inv.studies.first
    details = study.all_additional_potential_annotation_details
    assert_equal 3, details.count
    assert_equal ['end date of study', 'experimental site name', 'start date of study'], details.collect(&:label).sort

    path = "#{Rails.root}/test/fixtures/files/fair_data_station/indpensim.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first
    obs_unit = inv.studies.first.observation_units.first
    details = obs_unit.all_additional_potential_annotation_details
    assert_equal 6, details.count
    assert_equal ['brand', 'data stream', 'fermentation', 'ncbi taxonomy id', 'scientific name', 'volume'],
                 details.collect(&:label).sort
  end

  test 'get all_additional_potential_annotation_predicates' do
    path = "#{Rails.root}/test/fixtures/files/fair_data_station/seek-fair-data-station-test-case-irregular.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first
    study = inv.studies.first
    assert_equal ['http://fairbydesign.nl/ontology/end_date_of_study', 'http://fairbydesign.nl/ontology/experimental_site_name', 'http://fairbydesign.nl/ontology/start_date_of_study'],
                 study.all_additional_potential_annotation_predicates.sort
    obs_unit = study.observation_units.first
    assert_equal ['http://fairbydesign.nl/ontology/birth_weight', 'http://fairbydesign.nl/ontology/date_of_birth', 'https://w3id.org/mixs/0000811'],
                 obs_unit.all_additional_potential_annotation_predicates.sort
    sample = obs_unit.samples.first
    assert_equal ['http://fairbydesign.nl/ontology/biosafety_level', 'http://gbol.life/0.1/scientificName', 'http://purl.uniprot.org/core/organism', 'https://w3id.org/mixs/0000011'],
                 sample.all_additional_potential_annotation_predicates.sort
  end

  test 'find_exact_matching_extended_metadata_type' do
    path = "#{Rails.root}/test/fixtures/files/fair_data_station/seek-fair-data-station-test-case-irregular.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first
    study = inv.studies.first

    assert_nil study.find_exact_matching_extended_metadata_type
    partial_emt = FactoryBot.create(:fairdata_test_case_study_extended_metadata, title: 'partial matching')
    partial_emt.extended_metadata_attributes.delete(partial_emt.extended_metadata_attributes.last)
    partial_emt.reload
    assert_equal 2, partial_emt.extended_metadata_attributes.count
    assert_nil study.find_exact_matching_extended_metadata_type

    exact_match = FactoryBot.create(:fairdata_test_case_study_extended_metadata)
    assert_equal exact_match, study.find_exact_matching_extended_metadata_type

    #doesn't match if disabled
    exact_match.update_column(:enabled, false)
    assert_nil study.find_exact_matching_extended_metadata_type
  end

  test 'find_exact_matching_sample_type' do
    path = "#{Rails.root}/test/fixtures/files/fair_data_station/seek-fair-data-station-test-case-irregular.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first
    sample = inv.studies.first.observation_units.first.samples.first
    person = FactoryBot.create(:person)

    assert_nil sample.find_exact_matching_sample_type(person)
    partial_sample_type = FactoryBot.create(:fairdatastation_test_case_sample_type, title: 'partial matching')
    assert partial_sample_type.can_view?
    partial_sample_type.sample_attributes.delete(partial_sample_type.sample_attributes.last)
    partial_sample_type.reload
    assert_equal 5, partial_sample_type.sample_attributes.count
    assert_nil sample.find_exact_matching_sample_type(person)

    exact_match = FactoryBot.create(:fairdatastation_test_case_sample_type)
    assert exact_match.can_view?(person)
    assert_equal exact_match, sample.find_exact_matching_sample_type(person)
  end

  test 'find closest matching extended metadata type' do
    virtual_demo_assay = FactoryBot.create(:fairdata_virtual_demo_assay_extended_metadata)
    seek_test_case_assay = FactoryBot.create(:fairdata_test_case_assay_extended_metadata)
    FactoryBot.create(:simple_assay_extended_metadata_type)
    FactoryBot.create(:fairdata_test_case_obsv_unit_extended_metadata)
    FactoryBot.create(:simple_observation_unit_extended_metadata_type)
    Seek::FairDataStation::Writer.new

    path = "#{Rails.root}/test/fixtures/files/fair_data_station/seek-fair-data-station-test-case.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first
    assay = inv.studies.first.assays.first
    assert_equal seek_test_case_assay, assay.find_closest_matching_extended_metadata_type

    # but not if disabled
    seek_test_case_assay.update_column(:enabled, false)
    refute_equal seek_test_case_assay, assay.find_closest_matching_extended_metadata_type

    path = "#{Rails.root}/test/fixtures/files/fair_data_station/demo.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first
    assay = inv.studies.first.assays.first
    detected_type = assay.find_closest_matching_extended_metadata_type
    assert_equal virtual_demo_assay, detected_type

    path = "#{Rails.root}/test/fixtures/files/fair_data_station/indpensim.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first
    obs_unit = inv.studies.first.observation_units.first
    detected_type = obs_unit.find_closest_matching_extended_metadata_type
    assert_nil detected_type

    inpensim_obs_unit = FactoryBot.create(:fairdata_indpensim_obsv_unit_extended_metadata)
    detected_type = obs_unit.find_closest_matching_extended_metadata_type
    assert_equal inpensim_obs_unit, detected_type
  end

  test 'find closest matching sample type' do
    path = "#{Rails.root}/test/fixtures/files/fair_data_station/seek-fair-data-station-test-case.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first
    sample = inv.studies.first.observation_units.first.samples.first

    private_sample_type = FactoryBot.create(:fairdatastation_test_case_sample_type, policy: FactoryBot.create(:private_policy))
    refute private_sample_type.can_view?
    assert_nil sample.find_closest_matching_sample_type(nil)
    assert private_sample_type.can_view?(private_sample_type.contributor)
    assert_equal private_sample_type, sample.find_closest_matching_sample_type(private_sample_type.contributor)

    partial_sample_type = FactoryBot.create(:fairdatastation_test_case_sample_type)
    assert partial_sample_type.can_view?
    partial_sample_type.sample_attributes.delete(partial_sample_type.sample_attributes.last)
    partial_sample_type.reload
    assert_equal 5, partial_sample_type.sample_attributes.count
    assert_equal partial_sample_type, sample.find_closest_matching_sample_type(nil)

    less_close_sample_type = FactoryBot.create(:fairdatastation_test_case_sample_type)
    assert less_close_sample_type.can_view?
    less_close_sample_type.sample_attributes.delete(less_close_sample_type.sample_attributes.last)
    less_close_sample_type.sample_attributes.delete(less_close_sample_type.sample_attributes.last)
    less_close_sample_type.reload
    assert_equal 4, less_close_sample_type.sample_attributes.count

    assert_equal partial_sample_type, sample.find_closest_matching_sample_type(nil)
  end

  test 'find_exact_matching_sample_type dont pick if private' do
    path = "#{Rails.root}/test/fixtures/files/fair_data_station/seek-fair-data-station-test-case-irregular.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first
    sample = inv.studies.first.observation_units.first.samples.first
    person = FactoryBot.create(:person)

    exact_match = FactoryBot.create(:fairdatastation_test_case_sample_type, contributor: person, policy: FactoryBot.create(:private_policy))
    refute exact_match.can_view?
    assert_nil sample.find_exact_matching_sample_type(nil)
    assert exact_match.can_view?(person)
    assert_equal exact_match, sample.find_exact_matching_sample_type(person)
  end
end
