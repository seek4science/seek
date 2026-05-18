require 'test_helper'

class ExternalSearchTest < ActiveSupport::TestCase
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

  test 'search_adaptors returns enabled or all with include_disabled' do
    adaptor = @config_files.first
    key = adaptor['key']

    # Force adaptor OFF via config override
    Seek::Config.external_search_adaptors = { key => { 'enabled' => false } }
    Seek::Util.clear_cached

    result_files = Seek::ExternalSearch.instance.search_adaptors('all')
    adaptor_in_result = result_files.any? { |a| a.key == key }
    refute adaptor_in_result, 'disabled adaptor should not be included'

    # include disabled
    result_files = Seek::ExternalSearch.instance.search_adaptors('all', include_disabled: true)
    adaptor_in_result = result_files.any? { |a| a.key == key }
    assert adaptor_in_result, 'disabled adaptor should be included'

    Seek::Config.external_search_adaptors = { key => { 'enabled' => true } }
    Seek::Util.clear_cached

    result_files = Seek::ExternalSearch.instance.search_adaptors('all')
    adaptor_in_result = result_files.any? { |a| a.key == key }
    assert adaptor_in_result, 'enabled adaptor should be included'
  end

  test 'search_adaptors by type respects adaptors disabled by config' do
    # Find an adaptor with a specific search_type
    adaptor = @config_files.first

    key = adaptor['key']
    search_type = adaptor['search_type']
    results = Seek::ExternalSearch.instance.search_adaptors(search_type)
    assert results.any? { |a| a.key == key }, 'adaptor should be included before being disabled'

    # Disable adaptor
    Seek::Config.external_search_adaptors = { key => { 'enabled' => false } }
    Seek::Util.clear_cached

    results = Seek::ExternalSearch.instance.search_adaptors(search_type)
    refute results.any? { |a| a.key == key }, 'adaptor should not be included once disabled'
  end

  test 'search_adaptor_names respects enabled settings' do
    adaptor = @config_files.first
    key = adaptor['key']

    # Disable all adaptors
    setting = {}
    @config_files.each do |f|
      setting[f['key']] = { 'enabled' => false }
    end
    Seek::Config.external_search_adaptors = setting
    Seek::Util.clear_cached

    adaptor_names = Seek::ExternalSearch.instance.search_adaptor_names('all')
    refute adaptor_names.include?(adaptor['name']), 'Disabled adaptor should not appear in adaptor_names'

    # include disabled
    adaptor_names = Seek::ExternalSearch.instance.search_adaptor_names('all', include_disabled: true)
    assert adaptor_names.include?(adaptor['name']),
           'Disabled adaptor should appear in adaptor_names because include_disabled is true'

    # Re-enable the first adaptor
    setting[key] = { 'enabled' => true }
    Seek::Config.external_search_adaptors = setting
    Seek::Util.clear_cached

    adaptor_names = Seek::ExternalSearch.instance.search_adaptor_names('all')
    assert adaptor_names.include?(adaptor['name']), 'Enabled adaptor should appear in adaptor_names'
  end

  test 'external_search_supported returns false when all adaptors are disabled' do
    assert Seek::ExternalSearch.instance.supported?('all')
    # Disable all adaptors via config
    setting = {}
    @config_files.each do |f|
      setting[f['key']] = { 'enabled' => false }
    end
    Seek::Config.external_search_adaptors = setting
    Seek::Util.clear_cached

    refute Seek::ExternalSearch.instance.supported?('all'), 'Should not be supported when all adaptors are disabled'
  end

  test 'search adaptors' do
    adaptors = Seek::ExternalSearch.instance.search_adaptors
    assert adaptors.any?
    assert !adaptors.select { |a| a.is_a?(Seek::BiomodelsSearch::SearchBiomodelsAdaptor) }.empty?
    an_instance = adaptors.find { |a| a.is_a?(Seek::BiomodelsSearch::SearchBiomodelsAdaptor) }
    assert an_instance.is_a?(Seek::AbstractSearchAdaptor)
    assert an_instance.enabled?
    assert_equal 'BioModels Database', an_instance.name

    assert !adaptors.select { |a| a.is_a?(Seek::TessSearch::SearchTessAdaptor) }.empty?
    an_instance = adaptors.find { |a| a.is_a?(Seek::TessSearch::SearchTessAdaptor) }
    assert an_instance.is_a?(Seek::AbstractSearchAdaptor)
    assert an_instance.enabled?
    assert_equal 'ELIXIR TeSS Events', an_instance.name

    adaptors = Seek::ExternalSearch.instance.search_adaptors 'models'
    assert !adaptors.select { |a| a.is_a?(Seek::BiomodelsSearch::SearchBiomodelsAdaptor) }.empty?

    adaptors = Seek::ExternalSearch.instance.search_adaptors 'events'
    assert !adaptors.select { |a| a.is_a?(Seek::TessSearch::SearchTessAdaptor) }.empty?

    adaptors = Seek::ExternalSearch.instance.search_adaptors 'data_files'
    assert adaptors.select { |a| a.is_a?(Seek::BiomodelsSearch::SearchBiomodelsAdaptor) }.empty?
    assert adaptors.select { |a| a.is_a?(Seek::TessSearch::SearchTessAdaptor) }.empty?
  end

  test 'enabled?' do
    adaptors = Seek::ExternalSearch.instance.search_adaptors
    biomodels_adaptor = adaptors.find { |a| a.is_a?(Seek::BiomodelsSearch::SearchBiomodelsAdaptor) }

    with_config_value(:external_search_adaptors, { 'biomodels' => { 'enabled' => true } }) do
      assert biomodels_adaptor.enabled?
    end

    with_config_value(:external_search_adaptors, { 'biomodels' => { 'enabled' => false } }) do
      refute biomodels_adaptor.enabled?
    end
  end

  test 'search adaptor names' do
    assert (['BioModels Database',
             'ELIXIR TeSS Events'] - Seek::ExternalSearch.instance.search_adaptor_names('all')).blank?
    assert (['BioModels Database', 'ELIXIR TeSS Events'] - Seek::ExternalSearch.instance.search_adaptor_names).blank?
    assert_equal ['BioModels Database'], Seek::ExternalSearch.instance.search_adaptor_names('models')
    assert_equal ['ELIXIR TeSS Events'], Seek::ExternalSearch.instance.search_adaptor_names('events')
    assert_equal [], Seek::ExternalSearch.instance.search_adaptor_names('sops')
  end
end
