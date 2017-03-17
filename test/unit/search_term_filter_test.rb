require 'test_helper'

class SearchTermFilterTest < ActiveSupport::TestCase
  test 'filter asterix and question marks' do
    assert_equal 'fish', Seek::Search::SearchTermFilter.filter('*fis*h*')
    assert_equal 'fish', Seek::Search::SearchTermFilter.filter('?fis?h?')
  end

  test 'filter semi colon, but only from end' do
    assert_equal 'fish', Seek::Search::SearchTermFilter.filter('fish:')
    assert_equal 'fish', Seek::Search::SearchTermFilter.filter('fish:  ')
    assert_equal 'fish', Seek::Search::SearchTermFilter.filter('fish  :  ')
    assert_equal 'fish:2', Seek::Search::SearchTermFilter.filter('fish:2')
  end

  test 'filter out single hyphen' do
    assert_equal '', Seek::Search::SearchTermFilter.filter('-')
    assert_equal '', Seek::Search::SearchTermFilter.filter('  -   ')
    assert_equal 'fish-soup', Seek::Search::SearchTermFilter.filter('fish-soup')
  end

  test 'trims trailing spaces' do
    assert_equal 'fish', Seek::Search::SearchTermFilter.filter('   fish  ')
    assert_equal 'fish', Seek::Search::SearchTermFilter.filter("\tfish\t")
    assert_equal 'fish', Seek::Search::SearchTermFilter.filter("\nfish\n")
  end
end
