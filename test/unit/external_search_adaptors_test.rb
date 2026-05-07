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
      f['enabled'] == true || Seek::Config.external_search_adaptors.key?(f['key'])
    },
           'All returned adaptors should be enabled (either in YAML or config override)'
  end

  test 'search_adaptor_files respects adaptor_enabled? preference' do
    # Assume we have at least one adaptor; check first one
    assert @config_files.any?, 'Test requires at least one adaptor YAML file'

    adaptor = @config_files.first
    key = adaptor['key']

    # Verify it appears in search_adaptor_files when using the adaptor's YAML 'enabled' setting
    result_files = Seek::ExternalSearch.instance.search_adaptor_files('all')
    adaptor_in_result = result_files.any? { |f| f['key'] == key }

    if adaptor['enabled']
      assert adaptor_in_result, "Adaptor with 'enabled'=>true should appear in search_adaptor_files"
    else
      refute adaptor_in_result, "Adaptor with 'enabled'=>false should not appear in search_adaptor_files"
    end
  end

  test 'search_adaptor_files uses Seek::Config override when set' do
    adaptor = @config_files.first
    key = adaptor['key']

    # Force adaptor OFF via config override
    Seek::Config.external_search_adaptors = { key => false }
    Seek::Util.clear_cached

    result_files = Seek::ExternalSearch.instance.search_adaptor_files('all')
    adaptor_in_result = result_files.any? { |f| f['key'] == key }
    refute adaptor_in_result, 'Adaptor should be disabled when Seek::Config override is false'

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

  test 'backward compatibility: YAML enabled flag still works when no config override' do
    # Reset config
    Seek::Config.external_search_adaptors = {}
    Seek::Util.clear_cached

    # Get adaptors using only the YAML'enabled' flag (no overrides in config)
    files = Seek::ExternalSearch.instance.search_adaptor_files('all')

    # Check they match
    yaml_enabled_names = @config_files.select { |f| f['enabled'] == true }.map { |f| f['name'] }
    config_enabled_names = files.map { |f| f['name'] }

    assert_equal yaml_enabled_names.sort, config_enabled_names.sort,
                 'Should respect YAML enabled flags when no config override'
  end

  test 'config override takes precedence over YAML enabled flag' do
    adaptor = @config_files.first
    key = adaptor['key']

    # Set config override to the opposite of YAML's enabled flag
    override_value = !adaptor['enabled']
    Seek::Config.external_search_adaptors = { key => override_value }
    Seek::Util.clear_cached

    result_files = Seek::ExternalSearch.instance.search_adaptor_files('all')
    adaptor_in_result = result_files.any? { |f| f['key'] == key }

    if override_value
      assert adaptor_in_result, 'Config override should enable adaptor'
    else
      refute adaptor_in_result, 'Config override should disable adaptor'
    end
  end
end
