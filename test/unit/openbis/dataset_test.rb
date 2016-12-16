require 'test_helper'

class DatasetTest < ActiveSupport::TestCase
  def setup
    # FIXME: these tests rely on an external resource. This is currently useful whilst implementing, but eventually need mocking out somehow
    Seek::Openbis::ConnectionInfo.setup('apiuser', 'apiuser', 'https://openbis-api.fair-dom.org/openbis/openbis', 'https://openbis-api.fair-dom.org/datastore_server')
  end

  test 'find by perm ids' do
    ids = ['20160210130454955-23', 'no an id', '20160215111736723-31']
    sets = Seek::Openbis::Dataset.find_by_perm_ids(ids)
    assert_equal 2, sets.count
    assert_equal ['20160210130454955-23', '20160215111736723-31'], sets.collect(&:perm_id).sort

    #should be empty when presenting no ids
    sets = Seek::Openbis::Space.find_by_perm_ids([])
    assert_empty sets
  end

  test 'initialize' do
    dataset = Seek::Openbis::Dataset.new('20160210130454955-23')
    assert_equal '20160210130454955-23', dataset.perm_id
    assert_equal '20160210130454955-23', dataset.code

    # not recognised
    assert_raise_with_message(Seek::Openbis::EntityNotFoundException, 'Unable to find DataSet with perm id NOT-A-PERM-ID') do
      Seek::Openbis::Dataset.new('NOT-A-PERM-ID')
    end
  end

  test 'all' do
    all = Seek::Openbis::Dataset.all
    assert_equal 8, all.count
    assert_includes all.collect(&:perm_id), '20160210130454955-23'
  end

  test 'dataset files' do
    dataset = Seek::Openbis::Dataset.new('20160210130454955-23')
    files = dataset.dataset_files
  end
end
