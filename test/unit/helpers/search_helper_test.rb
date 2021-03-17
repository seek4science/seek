require 'test_helper'

class SearchHelperTest < ActionView::TestCase
  test 'external_search_supported' do
    with_config_value :external_search_enabled, false do
      refute external_search_supported?
    end

    with_config_value :external_search_enabled, true do
      assert external_search_supported?
    end
  end
end
