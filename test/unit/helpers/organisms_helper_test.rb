require 'test_helper'

class OrganismsHelperTest < ActionView::TestCase
  test 'bioportal search enabled' do
    with_config_value(:bioportal_api_key, '') do
      refute bioportal_search_enabled?
    end

    with_config_value(:bioportal_api_key, nil) do
      refute bioportal_search_enabled?
    end

    with_config_value(:bioportal_api_key, 'xxx-xxx-xxx-xxx') do
      assert bioportal_search_enabled?
    end
  end
end
