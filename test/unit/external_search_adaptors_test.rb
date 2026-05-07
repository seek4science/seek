require 'test_helper'

class ExternalSearchAdaptorsTest < ActiveSupport::TestCase
  def setup
    # Clear cache before each test
    Seek::Util.clear_cached
    Seek::ExternalSearch.instance.clear_cached
    # Reset external search adaptors config to defaults
    Seek::Config.external_search_adaptors = {}
    @config_files = Dir.glob(Rails.root.join('config', 'external_search_adaptors', '*.yml')).collect do |fn|
      YAML.load_file(fn)
    end
  end

  def teardown
    # Clean up after each test
    Seek::Util.clear_cached
    Seek::Config.external_search_adaptors = {}
  end

  test 'search_adaptor_files returns all enabled adaptors by default' do
    files = Seek::ExternalSearch.instance.search_adaptor_files('all')
    assert files.any?, 'Should return at least some adaptors'
    assert files.all? { |f|
      @config_files.find { |cf| cf['key'] == f['key'] }
    }, 'All returned adaptors should be enabled by default'
  end

  test 'search_adaptor_files uses Seek::Config when set and without include_disabled' do
    adaptor = @config_files.first
    key = adaptor['key']

    # Force adaptor OFF via config override
    Seek::Config.external_search_adaptors = { key => false }
    Seek::Util.clear_cached

    result_files = Seek::ExternalSearch.instance.search_adaptor_files('all')
    adaptor_in_result = result_files.any? { |f| f['key'] == key }
    refute adaptor_in_result, 'Adaptor should be disabled when Seek::Config override is false'

    # include disabled
    result_files = Seek::ExternalSearch.instance.search_adaptor_files('all', include_disabled: true)
    adaptor_in_result = result_files.any? { |f| f['key'] == key }
    assert adaptor_in_result, 'Adaptor should be disabled when Seek::Config override is false'

    # Force adaptor ON via config override (even if YAML says 'enabled'=>false)
    Seek::Config.external_search_adaptors = { key => true }
    Seek::Util.clear_cached

    result_files = Seek::ExternalSearch.instance.search_adaptor_files('all')
    adaptor_in_result = result_files.any? { |f| f['key'] == key }
    assert adaptor_in_result, 'Adaptor should be enabled when Seek::Config override is true'
  end

  test 'search_adaptor_files by type respects adaptors disabled by config' do
    # Find an adaptor with a specific search_type
    adaptor = @config_files.find { |f| f['search_type'].present? }

    key = adaptor['key']
    search_type = adaptor['search_type']

    # Disable all adaptors
    Seek::Config.external_search_adaptors = { key => false }
    Seek::Util.clear_cached

    result_files = Seek::ExternalSearch.instance.search_adaptor_files(search_type)
    adaptor_in_result = result_files.any? { |f| f['key'] == key }
    refute adaptor_in_result, 'Disabled adaptor should not appear in search_adaptor_files by type'
  end

  test 'external_search_adaptors can be set via Seek::Config' do
    overrides = { 'Seek::TessSearch::SearchTessAdaptor' => false,
                  'Seek::BiomodelsSearch::SearchBiomodelsAdaptor' => true }
    Seek::Config.external_search_adaptors = overrides
    Seek::Util.clear_cached

    result = Seek::Config.external_search_adaptors
    assert_equal overrides, result
  end

  test 'search_adaptor_names respects config overrides' do
    adaptor = @config_files.first
    key = adaptor['key']

    # Disable all adaptors
    setting = {}
    @config_files.each do |f|
      setting[f['key']] = false
    end
    Seek::Config.external_search_adaptors = setting
    Seek::Util.clear_cached

    adaptor_names = Seek::ExternalSearch.instance.search_adaptor_names('all')
    refute adaptor_names.include?(adaptor['name']), 'Disabled adaptor should not appear in adaptor_names'

    # Re-enable the first adaptor
    setting[key] = true
    Seek::Config.external_search_adaptors = setting
    Seek::Util.clear_cached

    adaptor_names = Seek::ExternalSearch.instance.search_adaptor_names('all')
    assert adaptor_names.include?(adaptor['name']), 'Enabled adaptor should appear in adaptor_names'
  end

  test 'search_adaptors returns instantiated adaptors only when enabled' do
    # Disable all
    setting = {}
    @config_files.each do |f|
      setting[f['key']] = false
    end
    Seek::Config.external_search_adaptors = setting
    Seek::Util.clear_cached

    adaptors = Seek::ExternalSearch.instance.search_adaptors('all')
    assert adaptors.empty?, 'Should have no adaptors when all are disabled'

    # Re-enable the first one
    first_key = @config_files.first['key']
    setting[first_key] = true
    Seek::Config.external_search_adaptors = setting
    Seek::Util.clear_cached

    adaptors = Seek::ExternalSearch.instance.search_adaptors('all')
    assert_equal 1, adaptors.count, 'Should have exactly one adaptor when only one is enabled'
  end

  test 'external_search_supported returns false when all adaptors are disabled' do
    # Disable all adaptors via config
    setting = {}
    @config_files.each do |f|
      setting[f['key']] = false
    end
    Seek::Config.external_search_adaptors = setting
    Seek::Util.clear_cached

    refute Seek::ExternalSearch.instance.supported?('all'), 'Should not be supported when all adaptors are disabled'
  end
end
