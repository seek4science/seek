require 'test_helper'

class SearchHelperTest < ActionView::TestCase

  test 'external_search_supported' do
    config_files = Seek::ExternalSearch.instance.search_adaptor_files('all', include_disabled: true)

    # all adaptors turned off
    setting = {}
    config_files.each do |f|
      setting[f['key']] = false
    end
    Seek::Config.external_search_adaptors = setting

    refute external_search_supported?

    # turn one on
    setting = {config_files.first['key'] => true}
    Seek::Config.external_search_adaptors = setting

    assert external_search_supported?
  end
end
