require 'test_helper'

class SearchHelperTest < ActionView::TestCase
  test 'external_search_supported' do
    with_config_value :external_search_enabled, false do
      with_config_value :crossref_api_email, nil do
        refute external_search_supported?
      end
      with_config_value :crossref_api_email, '' do
        refute external_search_supported?
      end
      with_config_value :crossref_api_email, 'fred@email.com' do
        refute external_search_supported?
      end
    end

    with_config_value :external_search_enabled, true do
      with_config_value :crossref_api_email, nil do
        refute external_search_supported?
      end
      with_config_value :crossref_api_email, '' do
        refute external_search_supported?
      end
      with_config_value :crossref_api_email, 'fred@email.com' do
        assert external_search_supported?
      end
    end
  end
end
