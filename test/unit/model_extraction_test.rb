require 'test_helper'
require 'storage_stub_helper'

class ModelExtractionTest < ActiveSupport::TestCase
  include Seek::Models::ModelExtraction
  include StorageStubHelper

  def test_model_contents_for_search
    model = FactoryBot.create :teusink_model
    contents = model_contents_for_search(model)

    assert contents.include?('KmPYKPEP')
    assert contents.include?('F16P')
  end

  def test_extract_sbml_species
    model = FactoryBot.create :teusink_model
    assert contains_sbml?(model)
    species = model.species
    assert species.include?('Glyc')
    assert !species.include?('KmPYKPEP')
    assert_equal 22, species.count

    # should be able to gracefully handle non sbml
    model = FactoryBot.create :non_sbml_xml_model
    assert_equal [], model.species
  end

  def test_sbml_parameter_extraction
    model = FactoryBot.create :teusink_model
    assert contains_sbml?(model)
    params = model.parameters_and_values
    assert !params.empty?
    assert params.keys.include?('KmPYKPEP')
    assert_equal '1306.45', params['VmPGK']

    # should be able to gracefully handle non sbml
    model = FactoryBot.create :non_sbml_xml_model
    assert_equal({}, model.parameters_and_values)
  end

  def test_extract_jwsdat_species
    model = FactoryBot.create :teusink_jws_model
    assert contains_jws_dat?(model)
    species = model.species
    assert species.include?('F16P')
    assert !species.include?('KmPYKPEP')
    assert_equal 14, species.count
  end

  def test_jwsdat_parameter_extraction
    model = FactoryBot.create :teusink_jws_model
    assert contains_jws_dat?(model)
    params = model.parameters_and_values
    assert !params.empty?
    assert_equal 97, params.keys.count
    assert params.keys.include?('KmPYKPEP')
    assert_equal '1306.45', params['VmPGK']
  end

  # On the S3 backend the content blob has no local filepath, so reading via
  # content_blob.filepath fails and was silently swallowed (rescue -> []/{}),
  # losing the species/parameters list with no error. Assert extraction reads
  # the file through the storage adapter and returns the same non-empty values
  # it does on local.
  test 'sbml species and parameters extracted from a blob on S3' do
    model = FactoryBot.create(:teusink_model)
    content = File.binread("#{Rails.root}/test/fixtures/files/Teusink.xml")
    # Re-find so no in-memory @data short-circuits the storage-adapter read.
    model = Model.find(model.id)

    with_stubbed_s3_storage do |dat, _converted|
      client = s3_client(dat)
      client.stub_responses(:head_object, content_length: content.bytesize)
      client.stub_responses(:get_object, body: content)

      species = model.species
      assert_equal 22, species.count, 'species lost on S3 (silent rescue -> [])'
      assert_includes species, 'Glyc'

      params = model.parameters_and_values
      assert_equal 88, params.keys.count, 'parameters lost on S3 (silent rescue -> {})'
      assert_includes params.keys, 'VmGLT'
      assert_equal '1306.45', params['VmPGK']
    end
  end

  test 'jws dat species and parameters extracted from a blob on S3' do
    model = FactoryBot.create(:teusink_jws_model)
    content = File.binread("#{Rails.root}/test/fixtures/files/Teusink2010921171725.dat")
    model = Model.find(model.id)

    with_stubbed_s3_storage do |dat, _converted|
      client = s3_client(dat)
      client.stub_responses(:head_object, content_length: content.bytesize)
      client.stub_responses(:get_object, body: content)

      species = model.species
      assert_equal 14, species.count, 'jws species lost on S3 (silent rescue -> [])'
      assert_includes species, 'F16P'

      params = model.parameters_and_values
      assert_equal 97, params.keys.count, 'jws parameters lost on S3 (silent rescue -> {})'
      assert_includes params.keys, 'KmPYKPEP'
      assert_equal '1306.45', params['VmPGK']
    end
  end
end
