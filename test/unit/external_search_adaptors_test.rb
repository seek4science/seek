require 'test_helper'

class ExternalSearchAdaptorsTest < ActiveSupport::TestCase
  def setup
    # Clear cache before each test
    Seek::Util.clear_cached
    # Reset external search adaptors config to defaults
    Seek::Config.external_search_adaptors = {}
  end

  def teardown
    # Clean up after each test
    Seek::Util.clear_cached
    Seek::Config.external_search_adaptors = {}
  end

  test 'search_adaptor_files returns all enabled adaptors by default' do
    files = Seek::ExternalSearch.instance.search_adaptor_files('all')
    assert files.any?, 'Should return at least some adaptors'
    assert files.all? { |f| f['enabled'] == true || Seek::Config.external_search_adaptors.key?(f['adaptor_class_name']) },
           'All returned adaptors should be enabled (either in YAML or config override)'
  end

  test 'search_adaptor_files respects adaptor_enabled? preference' do
    # Assume we have at least one adaptor; check first one
    files = Dir.glob(Rails.root.join('config', 'external_search_adaptors', '*.yml')).collect { |fn| YAML.load_file(fn) }
    assert files.any?, 'Test requires at least one adaptor YAML file'

    adaptor = files.first
    key = adaptor['adaptor_class_name']

    # Verify it appears in search_adaptor_files when using the adaptor's YAML 'enabled' setting
    result_files = Seek::ExternalSearch.instance.search_adaptor_files('all')
    adaptor_in_result = result_files.any? { |f| f['adaptor_class_name'] == key }

    if adaptor['enabled']
      assert adaptor_in_result, "Adaptor with 'enabled'=>true should appear in search_adaptor_files"
    else
      refute adaptor_in_result, "Adaptor with 'enabled'=>false should not appear in search_adaptor_files"
    end
  end

  test 'search_adaptor_files uses Seek::Config override when set' do
    files = Dir.glob(Rails.root.join('config', 'external_search_adaptors', '*.yml')).collect { |fn| YAML.load_file(fn) }
    skip 'No adaptors configured' if files.empty?

    adaptor = files.first
    key = adaptor['adaptor_class_name']
    original_enabled = adaptor['enabled']

    # Force adaptor OFF via config override
    Seek::Config.external_search_adaptors = { key => false }
    Seek::Util.clear_cached

    result_files = Seek::ExternalSearch.instance.search_adaptor_files('all')
    adaptor_in_result = result_files.any? { |f| f['adaptor_class_name'] == key }
    refute adaptor_in_result, "Adaptor should be disabled when Seek::Config override is false"

    # Force adaptor ON via config override (even if YAML says 'enabled'=>false)
    Seek::Config.external_search_adaptors = { key => true }
    Seek::Util.clear_cached

    result_files = Seek::ExternalSearch.instance.search_adaptor_files('all')
    adaptor_in_result = result_files.any? { |f| f['adaptor_class_name'] == key }
    assert adaptor_in_result, "Adaptor should be enabled when Seek::Config override is true"
  end

  test 'search_adaptor_files by type respects adaptors disabled by config' do
    # Find an adaptor that has a search_type (typically 'events' or 'models')
    files = Dir.glob(Rails.root.join('config', 'external_search_adaptors', '*.yml')).collect { |fn| YAML.load_file(fn) }
    skip 'No adaptors configured' if files.empty?

    # Find an adaptor with a specific search_type
    adaptor = files.find { |f| f['search_type'].present? }
    skip 'No adaptors with search_type configured' if adaptor.nil?

    key = adaptor['adaptor_class_name']
    search_type = adaptor['search_type']

    # Disable all adaptors
    Seek::Config.external_search_adaptors = { key => false }
    Seek::Util.clear_cached

    result_files = Seek::ExternalSearch.instance.search_adaptor_files(search_type)
    adaptor_in_result = result_files.any? { |f| f['adaptor_class_name'] == key }
    refute adaptor_in_result, "Disabled adaptor should not appear in search_adaptor_files by type"
  end

  test 'external_search_adaptors can be set via Seek::Config' do
    overrides = { 'Seek::TessSearch::SearchTessAdaptor' => false, 'Seek::BiomodelsSearch::SearchBiomodelsAdaptor' => true }
    Seek::Config.external_search_adaptors = overrides
    Seek::Util.clear_cached

    result = Seek::Config.external_search_adaptors
    assert_equal overrides, result
  end

  test 'search_adaptor_names respects config overrides' do
    files = Dir.glob(Rails.root.join('config', 'external_search_adaptors', '*.yml')).collect { |fn| YAML.load_file(fn) }
    skip 'No adaptors configured' if files.empty?

    adaptor = files.first
    key = adaptor['adaptor_class_name']

    # Disable all adaptors
    Seek::Config.external_search_adaptors = {}
    files.each do |f|
      Seek::Config.external_search_adaptors[f['adaptor_class_name']] = false
    end
    Seek::Util.clear_cached

    adaptor_names = Seek::ExternalSearch.instance.search_adaptor_names('all')
    refute adaptor_names.include?(adaptor['name']), 'Disabled adaptor should not appear in adaptor_names'

    # Re-enable the first adaptor
    Seek::Config.external_search_adaptors[key] = true
    Seek::Util.clear_cached

    adaptor_names = Seek::ExternalSearch.instance.search_adaptor_names('all')
    assert adaptor_names.include?(adaptor['name']), 'Enabled adaptor should appear in adaptor_names'
  end

  test 'search_adaptors returns instantiated adaptors only when enabled' do
    files = Dir.glob(Rails.root.join('config', 'external_search_adaptors', '*.yml')).collect { |fn| YAML.load_file(fn) }
    skip 'No adaptors configured' if files.empty?

    # Disable all
    Seek::Config.external_search_adaptors = {}
    files.each do |f|
      Seek::Config.external_search_adaptors[f['adaptor_class_name']] = false
    end
    Seek::Util.clear_cached

    adaptors = Seek::ExternalSearch.instance.search_adaptors('all')
    assert adaptors.empty?, 'Should have no adaptors when all are disabled'

    # Re-enable the first one
    first_key = files.first['adaptor_class_name']
    Seek::Config.external_search_adaptors[first_key] = true
    Seek::Util.clear_cached

    adaptors = Seek::ExternalSearch.instance.search_adaptors('all')
    assert_equal 1, adaptors.count, 'Should have exactly one adaptor when only one is enabled'
  end

  test 'external_search_supported returns false when all adaptors are disabled' do
    files = Dir.glob(Rails.root.join('config', 'external_search_adaptors', '*.yml')).collect { |fn| YAML.load_file(fn) }
    skip 'No adaptors configured' if files.empty?

    # Disable all adaptors via config
    Seek::Config.external_search_adaptors = {}
    files.each do |f|
      Seek::Config.external_search_adaptors[f['adaptor_class_name']] = false
    end
    Seek::Util.clear_cached

    # Also disable external_search globally
    with_config_value :external_search_enabled, true do
      assert !Seek::ExternalSearch.instance.supported?('all'), 'Should not be supported when all adaptors are disabled'
    end
  end

  test 'backward compatibility: YAML enabled flag still works when no config override' do
    # Reset config
    Seek::Config.external_search_adaptors = {}
    Seek::Util.clear_cached

    # Get adaptors using only the YAML'enabled' flag (no overrides in config)
    files = Seek::ExternalSearch.instance.search_adaptor_files('all')
    yaml_files = Dir.glob(Rails.root.join('config', 'external_search_adaptors', '*.yml')).collect { |fn| YAML.load_file(fn) }

    # Check they match
    yaml_enabled_names = yaml_files.select { |f| f['enabled'] == true }.map { |f| f['name'] }
    config_enabled_names = files.map { |f| f['name'] }

    assert_equal yaml_enabled_names.sort, config_enabled_names.sort, 'Should respect YAML enabled flags when no config override'
  end

  test 'config override takes precedence over YAML enabled flag' do
    files = Dir.glob(Rails.root.join('config', 'external_search_adaptors', '*.yml')).collect { |fn| YAML.load_file(fn) }
    skip 'No adaptors configured' if files.empty?

    adaptor = files.first
    key = adaptor['adaptor_class_name']

    # Set config override to the opposite of YAML's enabled flag
    override_value = !adaptor['enabled']
    Seek::Config.external_search_adaptors = { key => override_value }
    Seek::Util.clear_cached

    result_files = Seek::ExternalSearch.instance.search_adaptor_files('all')
    adaptor_in_result = result_files.any? { |f| f['adaptor_class_name'] == key }

    if override_value
      assert adaptor_in_result, 'Config override should enable adaptor'
    else
      refute adaptor_in_result, 'Config override should disable adaptor'
    end
  end
end

