require 'test_helper'

class SearchHelperTest < ActionView::TestCase

  test 'external_search_supported' do
    config_files = Dir.glob(Rails.root.join('config', 'external_search_adaptors', '*.yml')).collect do |fn|
      YAML.load_file(fn)
    end

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
