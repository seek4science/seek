require 'test_helper'

class SpaceTest < ActiveSupport::TestCase
  def setup
    # FIXME: these tests rely on an external resource. This is currently useful whilst implementing, but eventually need mocking out somehow
    Seek::Openbis::ConnectionInfo.setup('apiuser', 'apiuser', 'https://openbis-api.fair-dom.org/openbis/openbis', 'https://openbis-api.fair-dom.org/openbis/openbis')
  end

  test 'all' do
    all = Seek::Openbis::Space.all.sort_by(&:code)
    assert_equal 2, all.count
    assert_equal 'API-SPACE', all.first.code
    assert_equal 'API-SPACE', all.first.perm_id
    assert_equal 'use for testing openbis api integration ', all.first.description

    assert_equal 'DEFAULT', all.last.code
    assert_equal '', all.last.description
  end

  test 'initialize with permid' do
    space = Seek::Openbis::Space.new('API-SPACE')
    assert_equal 'API-SPACE', space.perm_id
    assert_equal 'API-SPACE', space.code
    assert_equal 'use for testing openbis api integration ', space.description

    # not recognised
    assert_raise_with_message(Seek::Openbis::EntityNotFoundException, 'Unable to find Space with perm id NOT-API-SPACE') do
      Seek::Openbis::Space.new('NOT-API-SPACE')
    end
  end

  test 'find by perm ids' do
    ids = ['API-SPACE', 'not a perm id', 'DEFAULT']
    spaces = Seek::Openbis::Space.find_by_perm_ids(ids)
    assert_equal 2, spaces.count
    assert_equal ['API-SPACE', 'DEFAULT'], spaces.collect(&:code).sort
  end

  test 'dataset count' do
    space = Seek::Openbis::Space.new('API-SPACE')
    assert_equal 8, space.dataset_count
  end

  test 'datasets' do
    space = Seek::Openbis::Space.new('API-SPACE')
    assert_equal 8, space.datasets.count
    assert_includes space.datasets.collect(&:perm_id), '20160210130454955-23'
  end
end
