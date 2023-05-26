require 'test_helper'
require 'openbis_test_helper'

class DatasetTest < ActiveSupport::TestCase
  def setup
    mock_openbis_calls
    @openbis_endpoint = FactoryBot.create(:openbis_endpoint)
  end

  test 'find by perm ids' do
    ids = ['20160210130454955-23', 'no an id', '20160215111736723-31']
    sets = Seek::Openbis::Dataset.new(@openbis_endpoint).find_by_perm_ids(ids)
    assert_equal 2, sets.count
    assert_equal ['20160210130454955-23', '20160215111736723-31'], sets.collect(&:perm_id).sort

    # should be empty when presenting no ids
    sets = Seek::Openbis::Dataset.new(@openbis_endpoint).find_by_perm_ids([])
    assert_empty sets
  end

  test 'find by perm ids of sample only sets' do
    ids = ['20171002172401546-38', '20171002190934144-40']
    sets = Seek::Openbis::Dataset.new(@openbis_endpoint).find_by_perm_ids(ids)
    assert_equal 2, sets.count
    assert_equal ['20171002172401546-38', '20171002190934144-40'], sets.collect(&:perm_id).sort
  end

  test 'initialize' do
    dataset = Seek::Openbis::Dataset.new(@openbis_endpoint, '20160210130454955-23')
    assert_equal '20160210130454955-23', dataset.perm_id
    assert_equal '20160210130454955-23', dataset.code

    # not recognised
    e = assert_raise(Seek::Openbis::EntityNotFoundException) do
      Seek::Openbis::Dataset.new(@openbis_endpoint, 'NOT-A-PERM-ID')
    end

    assert_equal 'Unable to find DataSet with perm id NOT-A-PERM-ID', e.message
  end

  test 'dates' do
    dataset = Seek::Openbis::Dataset.new(@openbis_endpoint, '20160210130454955-23')
    reg = dataset.registration_date
    assert reg.is_a?(DateTime)
    assert_equal '10 02 2016 12:04:55', reg.strftime('%d %m %Y %H:%M:%S')

    mod = dataset.modification_date
    assert mod.is_a?(DateTime)
    assert_equal '10 02 2016 12:04:55', mod.strftime('%d %m %Y %H:%M:%S')
  end

  test 'all' do
    all = Seek::Openbis::Dataset.new(@openbis_endpoint).all
    assert_equal 3, all.count
    assert_includes all.collect(&:perm_id), '20171004182824553-41'
  end

  test 'dataset files' do
    dataset = Seek::Openbis::Dataset.new(@openbis_endpoint, '20160210130454955-23')
    files = dataset.dataset_files
    assert_equal 3, files.count
    file = files.sort.last
    assert_equal 549_820, file.size
    assert_equal 'original/autumn.jpg', file.path
    refute file.is_directory
  end

  test 'refresh=true skips the cache on initialization' do
    explicit_query_mock

    txt = '{"datasets":[
        {"dataset_type":{"code":"TEST_DATASET_TYPE","description":"for api test"},
         "modificationDate":"2016-02-15 13:10:39.43","registerator":"tomek",
         "code":"20151217153943290-5",
         "experiment":"20151216143716562-2","modifier":"apiuser",
         "permId":"20151217153943290-5",
         "registrationDate":"2015-12-17 14:39:43.618571","properties":{"SEEK_DATAFILE_ID":"DataFile_1"},
         "samples":[],"tags":[]}]}'

    val = JSON.parse(txt)
    assert val
    assert_equal 'tomek', val['datasets'][0]['registerator']
    set_mocked_value_for_id('20151217153943290-5', val)

    dataset = Seek::Openbis::Dataset.new(@openbis_endpoint, '20151217153943290-5')
    assert_equal 'tomek', dataset.registrator

    txt = '{"datasets":[
        {"dataset_type":{"code":"TEST_DATASET_TYPE","description":"for api test"},
         "modificationDate":"2016-02-15 13:10:39.43","registerator":"bolek",
         "code":"20151217153943290-5",
         "experiment":"20151216143716562-2","modifier":"apiuser",
         "permId":"20151217153943290-5",
         "registrationDate":"2015-12-17 14:39:43.618571","properties":{"SEEK_DATAFILE_ID":"DataFile_1"},
         "samples":[],"tags":[]}]}'

    val = JSON.parse(txt)
    set_mocked_value_for_id('20151217153943290-5', val)

    dataset = Seek::Openbis::Dataset.new(@openbis_endpoint, '20151217153943290-5')
    assert_equal 'tomek', dataset.registrator

    dataset = Seek::Openbis::Dataset.new(@openbis_endpoint, '20151217153943290-5', true)
    assert_equal 'bolek', dataset.registrator

    dataset = Seek::Openbis::Dataset.new(@openbis_endpoint, '20151217153943290-5')
    assert_equal 'bolek', dataset.registrator
  end

  test 'explicit query mocking' do
    explicit_query_mock

    val = { key: 'val' }
    set_mocked_value_for_id('20160210130454955-23', val)

    res = Fairdom::OpenbisApi::ApplicationServerQuery.new(nil, nil).query(attributeValue: '20160210130454955-23', entityType: 'DataSet', queryType: 'ATTRIBUTE', attribute: 'PermID')
    assert_same val, res

    assert_raises(Exception) do
      Fairdom::OpenbisApi::ApplicationServerQuery.new(nil, nil).query(attributeValue: 'xxx', entityType: 'DataSet', queryType: 'ATTRIBUTE', attribute: 'PermID')
    end
  end

  # Test for original Stuart's code, I left to in case it has to be compared with new one
  #   test 'create datafile' do
  #     User.current_user = FactoryBot.create(:person).user
  #     @openbis_endpoint.project.update(default_license: 'wibble')
  #
  #     dataset = Seek::Openbis::Dataset.new(@openbis_endpoint, '20160210130454955-23')
  #     datafile = dataset.create_seek_datafile
  #     assert_equal DataFile, datafile.class
  #     refute_nil 1, datafile.content_blob
  #     assert datafile.valid?
  #     assert datafile.content_blob.valid?
  #
  #     assert datafile.openbis?
  #     assert datafile.content_blob.openbis?
  #     assert datafile.content_blob.custom_integration?
  #     refute datafile.content_blob.external_link?
  #     refute datafile.content_blob.show_as_external_link?
  #
  #     assert_equal "openbis:#{@openbis_endpoint.id}:dataset:20160210130454955-23", datafile.content_blob.url
  #     assert_equal 'wibble', datafile.license
  #
  #     normal = FactoryBot.create(:data_file)
  #     refute normal.openbis?
  #     refute normal.content_blob.openbis?
  #     refute normal.content_blob.custom_integration?
  #   end

  test 'registered?' do
    dataset = Seek::Openbis::Dataset.new(@openbis_endpoint, '20160210130454955-23')
    dataset2 = Seek::Openbis::Dataset.new(@openbis_endpoint, '20160215111736723-31')

    assert OpenbisExternalAsset.build(dataset).save

    assert dataset.registered?
    refute dataset2.registered?
  end

  test 'registered_as' do
    dataset = Seek::Openbis::Dataset.new(@openbis_endpoint, '20160210130454955-23')
    dataset2 = Seek::Openbis::Dataset.new(@openbis_endpoint, '20160215111736723-31')

    datafile = Seek::Openbis::SeekUtil.new.createDataFileFromObisSet(dataset, nil)
    assert datafile.save

    assert_equal datafile, dataset.registered_as
    assert_nil dataset2.registered_as
  end

  test 'construct_files_from_json makes DataFiles from json hash' do
    dataset = Seek::Openbis::Dataset.new(@openbis_endpoint, '20160210130454955-23')
    files_json = []

    files = dataset.construct_files_from_json(files_json)
    assert_equal [], files

    txt = '[
{"path":"","filePermId":"20160210130454955-23#","dataset":"20160210130454955-23","isDirectory":true,"fileLength":0},
{"path":"original","filePermId":"20160210130454955-23#original","dataset":"20160210130454955-23","isDirectory":true,"fileLength":0},
{"path":"original/DEFAULT","filePermId":"20160210130454955-23#original/DEFAULT","dataset":"20160210130454955-23","isDirectory":true,"fileLength":0},
{"path":"original/DEFAULT/Stanford_et_al-2015-Molecular_Systems_Biology.pdf","filePermId":"20160210130454955-23#original/DEFAULT/Stanford_et_al-2015-Molecular_Systems_Biology.pdf","dataset":"20160210130454955-23","isDirectory":false,"fileLength":430028},
{"path":"original/DEFAULT/fairdom-logo-compact.svg","filePermId":"20160210130454955-23#original/DEFAULT/fairdom-logo-compact.svg","dataset":"20160210130454955-23","isDirectory":false,"fileLength":9142}
]'
    files_json = JSON.parse txt
    files = dataset.construct_files_from_json(files_json)

    assert_equal 5, files.size
  end

  test 'populate_from_json uses serialized data_files if present' do
    dataset = Seek::Openbis::Dataset.new(@openbis_endpoint, '20160210130454955-23')
    refute dataset.json['dataset_files']
    assert_equal 1, dataset.dataset_file_count

    json = dataset.json.clone
    txt = '[
{"path":"","filePermId":"20160210130454955-23#","dataset":"20160210130454955-23","isDirectory":true,"fileLength":0},
{"path":"original","filePermId":"20160210130454955-23#original","dataset":"20160210130454955-23","isDirectory":true,"fileLength":0},
{"path":"original/DEFAULT","filePermId":"20160210130454955-23#original/DEFAULT","dataset":"20160210130454955-23","isDirectory":true,"fileLength":0},
{"path":"original/DEFAULT/Stanford_et_al-2015-Molecular_Systems_Biology.pdf","filePermId":"20160210130454955-23#original/DEFAULT/Stanford_et_al-2015-Molecular_Systems_Biology.pdf","dataset":"20160210130454955-23","isDirectory":false,"fileLength":2000},
{"path":"original/DEFAULT/fairdom-logo-compact.svg","filePermId":"20160210130454955-23#original/DEFAULT/fairdom-logo-compact.svg","dataset":"20160210130454955-23","isDirectory":false,"fileLength":500}
]'
    files_json = JSON.parse txt
    json['dataset_files'] = files_json

    dataset = Seek::Openbis::Dataset.new(@openbis_endpoint).populate_from_json(json)
    assert_equal 2, dataset.dataset_file_count
    assert_equal 2500, dataset.size
  end

  test 'prefetch_files queries for files and sets them in object and json' do
    dataset = Seek::Openbis::Dataset.new(@openbis_endpoint, '20160210130454955-23')
    json = dataset.json.clone
    json['dataset_files'] = []

    dataset = Seek::Openbis::Dataset.new(@openbis_endpoint).populate_from_json(json)
    assert_equal [], dataset.dataset_files
    assert_equal [], dataset.json['dataset_files']

    dataset.prefetch_files
    refute dataset.dataset_files.empty?
    refute dataset.json['dataset_files'].empty?
    assert_equal 3, dataset.dataset_files.size
    dataset.json['dataset_files'].each { |f| assert f }
  end
end
