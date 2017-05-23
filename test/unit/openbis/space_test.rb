require 'test_helper'
require 'openbis_test_helper'

class SpaceTest < ActiveSupport::TestCase
  def setup
    mock_openbis_calls
    @openbis_endpoint = Factory(:openbis_endpoint)
  end

  test 'all' do
    all = Seek::Openbis::Space.new(@openbis_endpoint).all.sort_by(&:code)
    assert_equal 2, all.count
    assert_equal 'API-SPACE', all.first.code
    assert_equal 'API-SPACE', all.first.perm_id
    assert_equal 'use for testing openbis api integration ', all.first.description

    assert_equal 'DEFAULT', all.last.code
    assert_equal '', all.last.description
  end

  test 'initialize with permid' do
    space = Seek::Openbis::Space.new(@openbis_endpoint, 'API-SPACE')
    assert_equal 'API-SPACE', space.perm_id
    assert_equal 'API-SPACE', space.code
    assert_equal 'use for testing openbis api integration ', space.description

    # not recognised
    e = assert_raise(Seek::Openbis::EntityNotFoundException) do
      Seek::Openbis::Space.new(@openbis_endpoint, 'NOT-API-SPACE')
    end

    assert_equal 'Unable to find Space with perm id NOT-API-SPACE', e.message
  end

  test 'dates' do
    space = Seek::Openbis::Space.new(@openbis_endpoint, 'API-SPACE')
    reg = space.registration_date
    assert reg.is_a?(DateTime)
    assert_equal '16 12 2015 12:51:20', reg.strftime('%d %m %Y %H:%M:%S')

    mod = space.modification_date
    assert mod.is_a?(DateTime)
    assert_equal '16 12 2015 12:51:20', mod.strftime('%d %m %Y %H:%M:%S')
  end

  test 'find by perm ids' do
    ids = ['API-SPACE', 'not a perm id', 'DEFAULT']
    spaces = Seek::Openbis::Space.new(@openbis_endpoint).find_by_perm_ids(ids)
    assert_equal 2, spaces.count
    assert_equal ['API-SPACE', 'DEFAULT'], spaces.collect(&:code).sort

    # should be empty when presenting no ids
    spaces = Seek::Openbis::Space.new(@openbis_endpoint).find_by_perm_ids([])
    assert_empty spaces
  end

  test 'dataset count' do
    space = Seek::Openbis::Space.new(@openbis_endpoint, 'API-SPACE')
    assert_equal 8, space.dataset_count
  end

  test 'datasets' do
    space = Seek::Openbis::Space.new(@openbis_endpoint, 'API-SPACE')
    assert_equal 8, space.datasets.count
    assert_includes space.datasets.collect(&:perm_id), '20160210130454955-23'
  end
end
