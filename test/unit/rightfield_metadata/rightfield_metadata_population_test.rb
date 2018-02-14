require 'test_helper'

# tests related to populating data file from rightfield metadata template
class RightfieldMetadataPopulationTest < ActiveSupport::TestCase
  test 'basic metadata population' do
    project = Factory(:project, id: 9999)
    assert_equal 9999, project.id
    blob = Factory(:rightfield_base_sample_template)
    data_file = DataFile.new(content_blob: blob)
    assert data_file.contains_extractable_spreadsheet?

    data_file.populate_metadata_from_template

    assert_equal 'My Title', data_file.title
    assert_equal 'My Description', data_file.description
    assert_equal [project], data_file.projects
  end

  test 'handles none excel blob' do
    blob = Factory(:txt_content_blob)
    data_file = DataFile.new(content_blob: blob)
    refute data_file.contains_extractable_spreadsheet?

    data_file.populate_metadata_from_template

    assert_nil data_file.title
    assert_nil data_file.description
  end

  test 'handles none rightfield blob' do
    blob = Factory(:small_test_spreadsheet_content_blob)
    data_file = DataFile.new(content_blob: blob)
    assert data_file.contains_extractable_spreadsheet?

    data_file.populate_metadata_from_template

    assert_nil data_file.title
    assert_nil data_file.description
  end

  test 'initialise assay as blank when missing' do
    blob = Factory(:small_test_spreadsheet_content_blob)
    data_file = DataFile.new(content_blob: blob)
    assay = data_file.initialise_assay_from_template
    refute_nil assay
    assert_nil assay.title
    assert_nil assay.description
    assert_nil assay.assay_type_uri
    assert_nil assay.technology_type_uri
    assert_equal Assay.new.inspect, assay.inspect

    blob = Factory(:rightfield_base_sample_template)
    data_file = DataFile.new(content_blob: blob)
    assay = data_file.initialise_assay_from_template
    refute_nil assay
    assert_nil assay.title
    assert_nil assay.description
    assert_nil assay.assay_type_uri
    assert_nil assay.technology_type_uri
    assert_equal Assay.new.inspect, assay.inspect
  end

  test 'initialise assay from template' do
    blob = Factory(:rightfield_base_sample_template_with_assay)
    data_file = DataFile.new(content_blob: blob)

    study = Factory(:study, id: 9999)
    assert_equal 9999, study.id

    project = Factory(:project, id: 9999)
    assert_equal 9999, project.id

    data_file.populate_metadata_from_template

    assert_equal 'My Title', data_file.title
    assert_equal 'My Description', data_file.description
    assert_equal [project], data_file.projects

    assay = data_file.initialise_assay_from_template
    refute_nil assay

    assert_equal 'My Assay Title',assay.title
    assert_equal 'My Assay Description',assay.description
    assert_equal 'http://jermontology.org/ontology/JERMOntology#Catabolic_response',assay.assay_type_uri
    assert_equal 'http://jermontology.org/ontology/JERMOntology#2-hybrid_system', assay.technology_type_uri
    assert_equal study, assay.study
  end

end
