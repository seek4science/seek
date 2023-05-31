require 'test_helper'

class SavedSearchTest < ActiveSupport::TestCase
  test 'title' do
    ss = FactoryBot.create :saved_search
    assert_equal "Search: 'cheese' (All)", ss.title

    ss = FactoryBot.create :saved_search, search_type: 'Models'
    assert_equal "Search: 'cheese' (Models)", ss.title

    ss = FactoryBot.create :saved_search, search_type: 'Models', include_external_search: true
    assert_equal "Search: 'cheese' (Models - including external sites)", ss.title
  end
end
