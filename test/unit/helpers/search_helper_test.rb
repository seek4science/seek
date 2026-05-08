require 'test_helper'

class SearchHelperTest < ActionView::TestCase

  test 'external_search_supported' do
    adaptors = Seek::ExternalSearch.instance.search_adaptors('all', include_disabled: true)

    # all adaptors turned off
    setting = {}
    adaptors.each do |adaptor|
      setting[adaptor.key] = false
    end
    Seek::Config.external_search_adaptors = setting

    refute external_search_supported?

    # turn one on
    setting = {adaptors.first.key => true}
    Seek::Config.external_search_adaptors = setting

    assert external_search_supported?
  end
end
