require 'test_helper'

class SearchHelperTest < ActionView::TestCase

  test 'external_search_supported' do
    adaptors = Seek::ExternalSearch.instance.search_adaptors('all', include_disabled: true)

    # all adaptors turned off
    setting = {}
    adaptors.each do |adaptor|
      setting[adaptor.key] = { 'enabled' => false }
    end
    with_config_value(:external_search_adaptors, setting) do
      refute external_search_supported?
    end

    # turn one on
    setting = { adaptors.first.key => { 'enabled' => true } }
    with_config_value(:external_search_adaptors, setting) do
      assert external_search_supported?
    end



  end
end
