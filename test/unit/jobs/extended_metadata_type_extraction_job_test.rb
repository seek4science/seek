require 'test_helper'

class PopulateExtendedMetadataTypeJobTest < ActiveSupport::TestCase

  fixtures :sample_attribute_types

  def setup
    @valid_emt_file = open_fixture_file('extended_metadata_type/valid_simple_emt.json')
    @invalid_emt_file = open_fixture_file('extended_metadata_type/invalid_emt_with_wrong_type.json')
    @dir = Rails.root.join('filestore', 'emt_files')
    FileUtils.mkdir_p(@dir)
  end


  test 'perform valid file' do
    job = PopulateExtendedMetadataTypeJob.new(@valid_emt_file)
    assert_difference('ExtendedMetadataType.count') do
      job.perform_now
    end
  end


  test 'perform invalid file with wrong type' do
    job = PopulateExtendedMetadataTypeJob.new(@invalid_emt_file)

    assert_no_difference('ExtendedMetadataType.count') do
      job.perform_now
    end

    errorfile = Rails.root.join(Seek::Config.append_filestore_path('emt_files'), 'result.error')
    assert File.exist?(errorfile)

    error_message = "The property '#/attributes/0/type' value \"String1\" did not match one of the following values: Date time, Date, Real number, Integer, Web link, Email address, Text, String, ChEBI, ECN, MetaNetX chemical, MetaNetX reaction, MetaNetX compartment, InChI, ENA custom date, Boolean, URI, DOI, NCBI ID, Registered Strain, Registered Data file"
    assert_includes File.read(errorfile), error_message

  end


  test 'perform invalid json file' do
    job = PopulateExtendedMetadataTypeJob.new(open_fixture_file('extended_metadata_type/invalid_json.json'))

    assert_no_difference('ExtendedMetadataType.count') do
       job.perform_now
    end

    errorfile = Rails.root.join(Seek::Config.append_filestore_path('emt_files'), 'result.error')
    assert File.exist?(errorfile)

    error_message = "Failed to parse JSON"
    assert_includes File.read(errorfile), error_message

  end


end
