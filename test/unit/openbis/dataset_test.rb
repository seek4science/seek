require 'test_helper'
require 'openbis_test_helper'

class DatasetTest < ActiveSupport::TestCase
  def setup
    mock_openbis_calls
    @openbis_endpoint = Factory(:openbis_endpoint)
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
    assert_equal 8, all.count
    assert_includes all.collect(&:perm_id), '20160210130454955-23'
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

  test 'create datafile' do
    User.current_user = Factory(:person).user
    @openbis_endpoint.project.update_attributes(default_license: 'wibble')

    dataset = Seek::Openbis::Dataset.new(@openbis_endpoint, '20160210130454955-23')
    datafile = dataset.create_seek_datafile
    assert_equal DataFile, datafile.class
    refute_nil 1, datafile.content_blob
    assert datafile.valid?
    assert datafile.content_blob.valid?

    assert datafile.openbis?
    assert datafile.content_blob.openbis?
    assert datafile.content_blob.custom_integration?
    refute datafile.content_blob.external_link?
    refute datafile.content_blob.show_as_external_link?

    assert_equal "openbis:#{@openbis_endpoint.id}:dataset:20160210130454955-23", datafile.content_blob.url
    assert_equal 'wibble', datafile.license

    normal = Factory(:data_file)
    refute normal.openbis?
    refute normal.content_blob.openbis?
    refute normal.content_blob.custom_integration?
  end

  test 'registered?' do
    blob = openbis_linked_content_blob('20160210130454955-23', @openbis_endpoint)
    dataset = Seek::Openbis::Dataset.new(@openbis_endpoint, '20160210130454955-23')
    dataset2 = Seek::Openbis::Dataset.new(@openbis_endpoint, '20160215111736723-31')

    assert dataset.registered?
    refute dataset2.registered?
  end
end
