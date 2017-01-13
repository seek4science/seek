require 'test_helper'

class DatasetTest < ActiveSupport::TestCase
  def setup
    @openbis_endpoint=Factory(:openbis_endpoint)
  end

  test 'find by perm ids' do
    ids = ['20160210130454955-23', 'no an id', '20160215111736723-31']
    sets = Seek::Openbis::Dataset.new(@openbis_endpoint).find_by_perm_ids(ids)
    assert_equal 2, sets.count
    assert_equal ['20160210130454955-23', '20160215111736723-31'], sets.collect(&:perm_id).sort

    #should be empty when presenting no ids
    sets = Seek::Openbis::Dataset.new(@openbis_endpoint).find_by_perm_ids([])
    assert_empty sets
  end

  test 'initialize' do
    dataset = Seek::Openbis::Dataset.new(@openbis_endpoint,'20160210130454955-23')
    assert_equal '20160210130454955-23', dataset.perm_id
    assert_equal '20160210130454955-23', dataset.code

    # not recognised
    assert_raise_with_message(Seek::Openbis::EntityNotFoundException, 'Unable to find DataSet with perm id NOT-A-PERM-ID') do
      Seek::Openbis::Dataset.new(@openbis_endpoint,'NOT-A-PERM-ID')
    end
  end

  test 'all' do
    all = Seek::Openbis::Dataset.new(@openbis_endpoint).all
    assert_equal 8, all.count
    assert_includes all.collect(&:perm_id), '20160210130454955-23'
  end

  test 'dataset files' do
    dataset = Seek::Openbis::Dataset.new(@openbis_endpoint,'20160210130454955-23')
    files = dataset.dataset_files
    assert_equal 3,files.count
    file=files.sort.last
    assert_equal 549820,file.size
    assert_equal 'original/autumn.jpg',file.path
    refute file.is_directory
  end

  test 'create datafile' do
    User.current_user=Factory(:person).user


    dataset = Seek::Openbis::Dataset.new(@openbis_endpoint,'20160210130454955-23')
    datafile = dataset.create_seek_datafile
    assert_equal DataFile,datafile.class
    assert_equal 1,datafile.content_blobs.count
    assert datafile.valid?
    assert datafile.content_blobs.first.valid?

    assert datafile.openbis?
    assert datafile.content_blobs.first.openbis?
    assert datafile.content_blobs.first.custom_integration?
    refute datafile.content_blobs.first.external_link?
    refute datafile.content_blobs.first.show_as_external_link?

    assert_equal "openbis:#{@openbis_endpoint.id}:dataset:20160210130454955-23",datafile.content_blobs.first.url

    normal = Factory(:data_file)
    refute normal.openbis?
    refute normal.content_blobs.first.openbis?
    refute normal.content_blobs.first.custom_integration?
  end

end
